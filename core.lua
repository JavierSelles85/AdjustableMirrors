local metadata = {
"## Interface:FS17 1.0.0.0",
"## Title: AdjustableMirrors (C)",
"## Notes: Mouse adjustable Mirrors (Core)",
"## Author: Marhu - Converted to FS17 by StjerneIdioten",
"## Version: 1.1.5",
"## Date: 24.07.2017",
"## Web: http://marhu.net - https://github.com/StjerneIdioten"
}
 
AdjustableMirrors = {};
AdjustableMirrors.sendNumBits = 7;
AdjustableMirrors.dir = g_currentModDirectory;

-- For debugging
local function log(...)
    if true then
        local txt = ""
        for idx = 1,select("#", ...) do
            txt = txt .. tostring(select(idx, ...))
        end
        print(string.format("%7ums AM.LUA ", (g_currentMission ~= nil and g_currentMission.time or 0)) .. txt);
    end
end;

function AdjustableMirrors.prerequisitesPresent(specializations)
    return true
end;

function AdjustableMirrors:load(savegame)

	--I think this disables mouse controls(for other functionality) if we are inside and adjusting mirrors.
	for i, camera in ipairs(self.cameras) do
		if camera.isInside then
			camera.Mirror_org_mouseEvent = camera.mouseEvent;
			camera.mouseEvent = function(cam, posX, posY, isDown, isUp, button)
				if not cam.MirrorAdjust then
					camera.Mirror_org_mouseEvent(cam, posX, posY, isDown, isUp, button)
				end
			end
		end;
    end;

	self.MirrorAdjustable = false
	self.MirrorAdjust = false;
	self.maxRot = math.rad(20);
	
	self.adjustMirror = {}
	local num = 1
	local function addMirror(mirror)
		self.adjustMirror[num] = {}
		self.adjustMirror[num].node = mirror;
		self.adjustMirror[num].OrgRot = {getRotation(self.adjustMirror[num].node)}
		self.adjustMirror[num].OrgTrans = {getTranslation(self.adjustMirror[num].node)}
		self.adjustMirror[num].base = createTransformGroup("Base")
		self.adjustMirror[num].x0 = 0
		self.adjustMirror[num].y0 = 0
		self.adjustMirror[num].x1 = createTransformGroup("x1")
		self.adjustMirror[num].x2 = createTransformGroup("x2")
		self.adjustMirror[num].y1 = createTransformGroup("y1")
		self.adjustMirror[num].y2 = createTransformGroup("y2")
		link(getParent(self.adjustMirror[num].node),self.adjustMirror[num].base)
		link(self.adjustMirror[num].base, self.adjustMirror[num].x1)
		link(self.adjustMirror[num].x1, self.adjustMirror[num].x2)
		link(self.adjustMirror[num].x2, self.adjustMirror[num].y1)
		link(self.adjustMirror[num].y1, self.adjustMirror[num].y2)
		link(self.adjustMirror[num].y2, self.adjustMirror[num].node)
		setTranslation(self.adjustMirror[num].base,unpack(self.adjustMirror[num].OrgTrans))
		setRotation(self.adjustMirror[num].base,unpack(self.adjustMirror[num].OrgRot))
		setTranslation(self.adjustMirror[num].x1,0,0,-0.25)
		setTranslation(self.adjustMirror[num].x2,0,0,0.5)
		setTranslation(self.adjustMirror[num].y1,-0.14,0,0)
		setTranslation(self.adjustMirror[num].y2,0.28,0,0)
		setTranslation(self.adjustMirror[num].node,-0.14,0,-0.25)
		setRotation(self.adjustMirror[num].node,0,0,0)
		num = num + 1
	end
	
	--This bit could perhaps be moved since it probably wont happen on the server side(Due to mirrors not being present on a dedicated server)
	if self.mirrors and self.mirrors[1] then
		for i = 1, table.getn(self.mirrors) do
			local numChildren = getNumOfChildren(self.mirrors[i].node);
			if numChildren > 0 then
				for j=numChildren,1,-1 do
					addMirror(getChildAt(self.mirrors[i].node, j-1));
				end
			else
				addMirror(self.mirrors[i].node);
			end;
		end;
	end;

	--Checks for the savegame files, which means that clients on a multiplayer game probably wont get any further that here.
	if savegame ~= nil and not savegame.resetVehicles then
		log("Loading in mirror settings from savegame");

		--Need to check whether this is a multiplayer game or not due to mirrors not being present on dedicated server vehichles
		if g_currentMission.missionDynamicInfo.isMultiplayer then
			log("This is a multiplayer session");

			--If this is a multiplayer game we need to know if this is the server or a client
			if self.isServer then
				--This is the server, so we load in the mirror data from the xml file, if it exists, and create the proper file structures
				log("This is the server")

				local i = 1
				local mirrorKey = savegame.key..".mirror"
				while hasXMLProperty(savegame.xmlFile, mirrorKey..i) do
					self.adjustMirror[i] = {}
					self.adjustMirror[i].x0 = getXMLFloat(savegame.xmlFile, mirrorKey.. i .. "#rotx");
					self.adjustMirror[i].y0 = getXMLFloat(savegame.xmlFile, mirrorKey.. i .. "#roty");

					log("Mirror"..i)
					log(string.format("rotx: %s",(self.adjustMirror[i].x0)))
					log(string.format("roty: %s",(self.adjustMirror[i].y0)))

					i = i + 1;
				end;

				--Need to check if the server is also a client, because then the mirrors should also be adjusted

			else
				log("This is a client")
			end;	
		else
			log("This is not a multiplayer session")
			--If this it not a multiplayer game, then just load in settings from the vehichle xml. And set the mirrors accordingly.
			for i=1, table.getn(self.adjustMirror) do
				local mirrorKey = savegame.key..".mirror"..i;
				self.adjustMirror[i].x0 = Utils.getNoNil(getXMLFloat(savegame.xmlFile, mirrorKey .. "#rotx"), self.adjustMirror[i].x0);
				self.adjustMirror[i].y0 = Utils.getNoNil(getXMLFloat(savegame.xmlFile, mirrorKey .. "#roty"), self.adjustMirror[i].y0);
				setRotation(self.adjustMirror[i].x1,math.min(0,self.adjustMirror[i].x0),0,0);
				setRotation(self.adjustMirror[i].x2,math.max(0,self.adjustMirror[i].x0),0,0);
				setRotation(self.adjustMirror[i].y1,0,0,math.max(0,self.adjustMirror[i].y0));
				setRotation(self.adjustMirror[i].y2,0,0,math.min(0,self.adjustMirror[i].y0));

				log("Mirror"..i)
				log(string.format("rotx: %s",(self.adjustMirror[i].x0)))
				log(string.format("roty: %s",(self.adjustMirror[i].y0)))

			end;
		end;

		log("Done loading in mirror data")

	end;
end;

function AdjustableMirrors:delete()
	
end;

function AdjustableMirrors:mouseEvent(posX, posY, isDown, isUp, button)
	
	---[[

	if self.MirrorAdjustable == true then
	
		if isDown and button == 1 then
			self.MirrorAdjust = true;
		elseif isUp and button == 1 then
			self.MirrorAdjust = false;
		end;
		
		if isDown and button == 2 then
			if self.mirrors and self.mirrors[1] and not getVisibility(self.mirrors[1]) then
				local g = getfenv(0)
				g.g_rearMirrorsAvailable = true;
				g.g_settingsRearMirrors = true;
				for i=1,table.getn(g_currentMission.vehicles) do
					if g_currentMission.vehicles[i].mirrors and g_currentMission.vehicles[i].mirrors[1] then
						g_currentMission.vehicles[i].mirrorAvailable = true;
					end;
				end;
			end;
		end;
		
		self.cameras[self.camIndex].MirrorAdjust = self.MirrorAdjust;
	
		if self.MirrorAdjust then
			local movex = 0
			local movey = 0
		
			if InputBinding.wrapMousePositionEnabled then
				movex = InputBinding.mouseMovementX
				movey = InputBinding.mouseMovementY
			else
				movex = InputBinding.mouseMovementX
				movey = InputBinding.mouseMovementY
			end;
			local MirrorSelect 
			for i=1,table.getn(self.adjustMirror) do
				local x,y,z = getWorldTranslation(self.adjustMirror[i].base);
				x,y,z = project(x,y,z);
				if x >= 0.4 and x <= 0.6 then
					if y >= 0.4 and y <= 0.6 then
						if z <= 1 then
							MirrorSelect = i	
							break;
						end;
					end;
				end;
			end;
			if MirrorSelect ~= nil then
				self.adjustMirror[MirrorSelect].x0 = math.min(self.maxRot,math.max(-self.maxRot,self.adjustMirror[MirrorSelect].x0 + movey))
				self.adjustMirror[MirrorSelect].y0 = math.min(self.maxRot,math.max(-self.maxRot,self.adjustMirror[MirrorSelect].y0 + movex))
				setRotation(self.adjustMirror[MirrorSelect].x1,math.min(0,self.adjustMirror[MirrorSelect].x0),0,0);
				setRotation(self.adjustMirror[MirrorSelect].x2,math.max(0,self.adjustMirror[MirrorSelect].x0),0,0);
				setRotation(self.adjustMirror[MirrorSelect].y1,0,0,math.max(0,self.adjustMirror[MirrorSelect].y0));
				setRotation(self.adjustMirror[MirrorSelect].y2,0,0,math.min(0,self.adjustMirror[MirrorSelect].y0));
			end
		end
	else
		self.cameras[self.camIndex].MirrorAdjust = false
	end

	--]]

end;

function AdjustableMirrors:keyEvent(unicode, sym, modifier, isDown)
end;

---[[

function AdjustableMirrors:readStream(streamId, connection)

	log("Receiving mirror stream on connect:")
	if connection:getIsServer() then
		--Check if the server has mirror settings stored for the vehicle
		if streamReadBool(streamId) then 
			log("Server has mirror settings")

			for i=1, table.getn(self.adjustMirror) do

				log(string.format("mirror%s",(i)))

				--self.adjustMirror[i].x0 = streamReadUIntN(streamId, AdjustableMirrors.sendNumBits) / (2^AdjustableMirrors.sendNumBits - 1);
				--self.adjustMirror[i].y0 = streamReadUIntN(streamId, AdjustableMirrors.sendNumBits) / (2^AdjustableMirrors.sendNumBits - 1);

				self.adjustMirror[i].x0 = streamReadFloat32(streamId);
				self.adjustMirror[i].y0 = streamReadFloat32(streamId);

				log(string.format("rotx: %s",(self.adjustMirror[i].x0)))
				log(string.format("roty: %s",(self.adjustMirror[i].y0)))

				log("Mirror loaded!")

			end;

		else
			log("Server does not have mirror settings")
		end;

		--Set the rotation of the mirrors, either to defaults or the loaded values.
		for i=1, table.getn(self.adjustMirror) do
			setRotation(self.adjustMirror[i].x1,math.min(0,self.adjustMirror[i].x0),0,0);
			setRotation(self.adjustMirror[i].x2,math.max(0,self.adjustMirror[i].x0),0,0);
			setRotation(self.adjustMirror[i].y1,0,0,math.max(0,self.adjustMirror[i].y0));
			setRotation(self.adjustMirror[i].y2,0,0,math.min(0,self.adjustMirror[i].y0));
		end;
	end;
	log("Done width mirror stream:")

end;

function AdjustableMirrors:writeStream(streamId, connection)

	log("Writing mirror stream:")

	if not connection:getIsServer() then
		log("Server:")

		---[[

		if table.getn(self.adjustMirror) > 0 then

			--Inform the client that we have mirror settings stored
			streamWriteBool(streamId, true)

			for i=1,table.getn(self.adjustMirror) do

				log(string.format("mirror%s",(i)))

				--streamWriteIntN(streamId, self.adjustMirror[i].x0 * (2^AdjustableMirrors.sendNumBits - 1), AdjustableMirrors.sendNumBits)
				--streamWriteIntN(streamId, self.adjustMirror[i].y0 * (2^AdjustableMirrors.sendNumBits - 1), AdjustableMirrors.sendNumBits)
				streamWriteFloat32(streamId, self.adjustMirror[i].x0)
				streamWriteFloat32(streamId, self.adjustMirror[i].y0)

				log(string.format("rotx: %s",(self.adjustMirror[i].x0)))
				log(string.format("roty: %s",(self.adjustMirror[i].y0)))

			end

		else
			--No mirror settings stored for this vehicle
			streamWriteBool(streamId, false)
			log("No mirror settings stored for this vehicle")
		end

		--]]

	end;

	log("Done writing mirror stream")

end;

function AdjustableMirrors:readUpdateStream(streamId, timestamp, connection)
    if not connection:getIsServer() then
		
	end;
end;
 
function AdjustableMirrors:writeUpdateStream(streamId, connection, dirtyMask)
    if connection:getIsServer() then
      
    end;
end;
 
function AdjustableMirrors:getSaveAttributesAndNodes(nodeIdent)

	local attributes = "";
    local nodes = "";
			  
	for i=1,table.getn(self.adjustMirror) do
		if i > 1 then nodes = nodes.."\n"; end;
		nodes = nodes.. nodeIdent..'<mirror'..i..' rotx="'..self.adjustMirror[i].x0..'" roty="'..self.adjustMirror[i].y0..'" />';
	end
		
    return attributes,nodes;

end

--]]

function AdjustableMirrors:update(dt)

	if self.isEntered and self.isClient and self:getIsActiveForInput(false) and self.cameras[self.camIndex].isInside then

		self.showMirrorPrompt = true

		if InputBinding.hasEvent(InputBinding.adjustableMirrors_ADJUSTMIRRORS) then
			if self.mirrors and self.mirrors[1] then
				self.MirrorAdjustable = not self.MirrorAdjustable;
				InputBinding.MirrorAdjustable = self.MirrorAdjustable;
			end;
		end;

	else

		self.showMirrorPrompt = false

	end

	--[[

	elseif self.MirrorAdjustable or self.MirrorAdjust then
		self.MirrorAdjustable = false;
		self.MirrorAdjust = false;
		InputBinding.MirrorAdjustable = false;
	end
	
	--]]

end;

function AdjustableMirrors:updateTick(dt)	

end;

function AdjustableMirrors:draw()
	if self.showMirrorPrompt then
		if self.MirrorAdjustable then
			g_currentMission:addHelpButtonText(g_i18n:getText("adjustableMirrors_ADJUSTMIRRORS_Off"), InputBinding.adjustableMirrors_ADJUSTMIRRORS, nil, GS_PRIO_VERY_HIGH);
		else
			g_currentMission:addHelpButtonText(g_i18n:getText("adjustableMirrors_ADJUSTMIRRORS"), InputBinding.adjustableMirrors_ADJUSTMIRRORS, nil, GS_PRIO_VERY_HIGH);
		end
	end
end;

---[[

function AdjustableMirrors:onEnter()

	--[[
	log("Enter event triggered at "..self.controllerName)
	if g_server == nil then
		for a=1, table.getn(g_currentMission.users) do
			local user = g_currentMission.users[a];
			if user.userId == g_currentMission.playerUserId then
				if user.nickname == self.controllerName then
					log(user.nickname.." entered vehicle:")
				end;
				break;
			end;
		end;
	end;

	--]]

	--DebugUtil.printTableRecursively(self,"-",0,2)

	--[[

	self.MirrorAdjustable = false;
	self.MirrorAdjust = false;
	InputBinding.MirrorAdjustable = false;
	for i=1,table.getn(self.cameras) do
		self.cameras[i].MirrorAdjust = nil
	end

	--]]

end;


function AdjustableMirrors:onLeave()
	if g_server == nil then
		for a=1, table.getn(g_currentMission.users) do
			local user = g_currentMission.users[a];
			if user.userId == g_currentMission.playerUserId then
				log("This is "..user.nickname.." registering exit event:")
				if user.nickname == self.controllerName then
					log("Leaving vehicle, sending event from client "..user.nickname)
					g_client:getServerConnection():sendEvent(AMUpdateEvent:new(self, nil));
				end;
				break;
			end;
		end;
	end

	--[[
	self.MirrorAdjustable = false;
	self.MirrorAdjust = false;
	InputBinding.MirrorAdjustable = false;
	for i=1,table.getn(self.cameras) do
		self.cameras[i].MirrorAdjust = nil
	end
	--]]

end;

function AdjustableMirrors.updateMirror(self)
	log("Updating mirror")
	for i=1, table.getn(self.adjustMirror) do
		setRotation(self.adjustMirror[i].x1,math.min(0,self.adjustMirror[i].x0),0,0);
		setRotation(self.adjustMirror[i].x2,math.max(0,self.adjustMirror[i].x0),0,0);
		setRotation(self.adjustMirror[i].y1,0,0,math.max(0,self.adjustMirror[i].y0));
		setRotation(self.adjustMirror[i].y2,0,0,math.min(0,self.adjustMirror[i].y0));
	end;
end

--[[
local org_InputBinding_isAxisZero = InputBinding.isAxisZero
InputBinding.isAxisZero = function(v)
	if InputBinding.MirrorAdjustable then v = nil end;
	return v == nil or math.abs(v) < 0.0001;
end
--]]

---
---
---

AMUpdateEvent = {};
AMUpdateEvent_mt = Class(AMUpdateEvent, Event);
InitEventClass(AMUpdateEvent, "AMUpdateEvent");

function AMUpdateEvent:emptyNew()
	log("New empty event")
    local self = Event:new(AMUpdateEvent_mt);
	self.className = "AMUpdateEvent"
    return self;
end;

function AMUpdateEvent:new(vehicle)
	log("New event")
    local self = AMUpdateEvent:emptyNew()
    self.vehicle = vehicle
    return self;
end;

function AMUpdateEvent:readStream(streamId, connection)
	log("Reading stream")
	self.vehicle = readNetworkNodeObject(streamId);

	if self.vehicle ~= nil then
		log("Vehicle was not nil")
		if g_server ~= nil then
			log("This is the server reading stream")

			local clientName = streamReadString(streamId)

			log("Client is "..clientName)

			local numberOfMirrors = streamReadInt8(streamId)
			log("Number of mirrors: "..numberOfMirrors)

			for i=1, numberOfMirrors do

				log(string.format("mirror%s",(i)))

				self.vehicle.adjustMirror[i] = {}
				self.vehicle.adjustMirror[i].x0 = streamReadFloat32(streamId);
				self.vehicle.adjustMirror[i].y0 = streamReadFloat32(streamId);

				--self.vehicle.adjustMirror[i].x0 = streamReadUIntN(streamId, AdjustableMirrors.sendNumBits) / (2^AdjustableMirrors.sendNumBits - 1);
				--self.vehicle.adjustMirror[i].y0 = streamReadUIntN(streamId, AdjustableMirrors.sendNumBits) / (2^AdjustableMirrors.sendNumBits - 1);

				log(string.format("rotx: %s",(self.vehicle.adjustMirror[i].x0)))
				log(string.format("roty: %s",(self.vehicle.adjustMirror[i].y0)))
				log("Mirror loaded!")
			end;

			log("Server broadcasting event")

			g_server:broadcastEvent(AMUpdateEvent:new(self.vehicle), nil, nil, self.vehicle);

		elseif g_client ~= nil then
			for a=1, table.getn(g_currentMission.users) do
				local user = g_currentMission.users[a];
				if user.userId == g_currentMission.playerUserId then
					log("This is "..user.nickname.." reading a client stream:")
					break;
				end;
			end;

			--For each mirror send the settings
			for i=1,table.getn(self.vehicle.adjustMirror) do
				log(string.format("mirror%s",(i)))

				--local newX = self.vehicle.adjustMirror[i].x0 * (2^AdjustableMirrors.sendNumBits - 1)
				--local newY = self.vehicle.adjustMirror[i].y0 * (2^AdjustableMirrors.sendNumBits - 1)

				self.vehicle.adjustMirror[i].x0 = streamReadFloat32(streamId);
				self.vehicle.adjustMirror[i].y0 = streamReadFloat32(streamId);

				log(string.format("rotx: %s",(self.vehicle.adjustMirror[i].x0)))
				log(string.format("roty: %s",(self.vehicle.adjustMirror[i].y0)))
			end

			log("Updating mirrors")
			AdjustableMirrors.updateMirror(self.vehicle)
		end;
	end;
	log("Done reading stream")
end;

function AMUpdateEvent:writeStream(streamId, connection)
	log("Writing stream")
	writeNetworkNodeObject(streamId, self.vehicle);
	if g_server == nil then

		for a=1, table.getn(g_currentMission.users) do
			local user = g_currentMission.users[a];
			if user.userId == g_currentMission.playerUserId then
				log("This is "..user.nickname.." writing a client stream:")
				streamWriteString(streamId, user.nickname)
				break;
			end;
		end;

		

		--Sending the number of mirrors so the server can prepare
		log("Number of mirrors: "..table.getn(self.vehicle.adjustMirror))
		streamWriteInt8(streamId, table.getn(self.vehicle.adjustMirror))

		--For each mirror send the settings
		for i=1,table.getn(self.vehicle.adjustMirror) do
			log(string.format("mirror%s",(i)))

			--local newX = self.vehicle.adjustMirror[i].x0 * (2^AdjustableMirrors.sendNumBits - 1)
			--local newY = self.vehicle.adjustMirror[i].y0 * (2^AdjustableMirrors.sendNumBits - 1)

			streamWriteFloat32(streamId, self.vehicle.adjustMirror[i].x0)
			streamWriteFloat32(streamId, self.vehicle.adjustMirror[i].y0)

			log(string.format("rotx: %s",(self.vehicle.adjustMirror[i].x0)))
			log(string.format("roty: %s",(self.vehicle.adjustMirror[i].y0)))
		end
	elseif g_server ~= nil then
		log("This is a server writing stream:")

		--For each mirror send the settings
		for i=1,table.getn(self.vehicle.adjustMirror) do
			log(string.format("mirror%s",(i)))

			--local newX = self.vehicle.adjustMirror[i].x0 * (2^AdjustableMirrors.sendNumBits - 1)
			--local newY = self.vehicle.adjustMirror[i].y0 * (2^AdjustableMirrors.sendNumBits - 1)

			streamWriteFloat32(streamId, self.vehicle.adjustMirror[i].x0)
			streamWriteFloat32(streamId, self.vehicle.adjustMirror[i].y0)

			log(string.format("rotx: %s",(self.vehicle.adjustMirror[i].x0)))
			log(string.format("roty: %s",(self.vehicle.adjustMirror[i].y0)))
		end
	end

	log("Done writing stream")
end;

---
---
---

--- Log Info ---
local function autor() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Author: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
local function name() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Title: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
local function version() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Version: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
local function support() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Web: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
print(string.format("Script %s v%s by %s loaded! Support on %s",(name()),(version()),(autor()),(support())));