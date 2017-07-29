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

function AdjustableMirrors.prerequisitesPresent(specializations)
    return true
end;

function AdjustableMirrors:load(savegame)

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
		print("Loading in mirror settings");

		--Need to check whether this is a multiplayer game or not due to mirrors not being present on dedicated server vehichles
		if g_currentMission.missionDynamicInfo.isMultiplayer then
			print("\tThis is a multiplayer session");

			--If this is a multiplayer game we need to know if this is the server or a client
			if self.isServer then
				--This is the server, so we load in the mirror data from the xml file, if it exists, and create the proper file structures
				print("\t\tThis is the server")

				local i = 1
				local mirrorKey = savegame.key..".mirror"
				while hasXMLProperty(savegame.xmlFile, mirrorKey..i) do
					self.adjustMirror[i] = {}
					self.adjustMirror[i].x0 = getXMLFloat(savegame.xmlFile, mirrorKey.. i .. "#rotx");
					self.adjustMirror[i].y0 = getXMLFloat(savegame.xmlFile, mirrorKey.. i .. "#roty");

					print("\t\tMirror"..i)
					print(string.format("\t\t\trotx: %s\n\t\t\troty: %s",(self.adjustMirror[i].x0),(self.adjustMirror[i].y0)))

					i = i + 1;
				end;
			else
				print("\tThis is a client")
			end;	
		else
			print("\tThis is not a multiplayer session")
			--If this it not a multiplayer game, then just load in settings from the vehichle xml. And set the mirrors accordingly.
			for i=1, table.getn(self.adjustMirror) do
				local mirrorKey = savegame.key..".mirror"..i;
				self.adjustMirror[i].x0 = Utils.getNoNil(getXMLFloat(savegame.xmlFile, mirrorKey .. "#rotx"), self.adjustMirror[i].x0);
				self.adjustMirror[i].y0 = Utils.getNoNil(getXMLFloat(savegame.xmlFile, mirrorKey .. "#roty"), self.adjustMirror[i].y0);
				setRotation(self.adjustMirror[i].x1,math.min(0,self.adjustMirror[i].x0),0,0);
				setRotation(self.adjustMirror[i].x2,math.max(0,self.adjustMirror[i].x0),0,0);
				setRotation(self.adjustMirror[i].y1,0,0,math.max(0,self.adjustMirror[i].y0));
				setRotation(self.adjustMirror[i].y2,0,0,math.min(0,self.adjustMirror[i].y0));

				print("\t\tMirror"..i)
				print(string.format("\t\t\trotx: %s\n\t\t\troty: %s",(self.adjustMirror[i].x0),(self.adjustMirror[i].y0)))

			end;
		end;

		print("\tDone")

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

	print("Receiving mirror stream:")
	if connection:getIsServer() then
		--Check if the server has mirror settings stored for the vehicle
		if streamReadBool(streamId) then 
			print("\tServer has mirror settings")

			for i=1, table.getn(self.adjustMirror) do

				print(string.format("\t\tmirror%s",(i)))

				self.adjustMirror[i].x0 = streamReadUIntN(streamId, AdjustableMirrors.sendNumBits) / (2^AdjustableMirrors.sendNumBits - 1);
				self.adjustMirror[i].y0 = streamReadUIntN(streamId, AdjustableMirrors.sendNumBits) / (2^AdjustableMirrors.sendNumBits - 1);

				print(string.format("\t\t\trotx:%f\n\t\t\troty:%f",(self.adjustMirror[i].x0),(self.adjustMirror[i].y0)))

				print("\t\t\tMirror loaded!")

			end;

		else
			print("\tServer does not have mirror settings")
		end;

		--Set the rotation of the mirrors, either to defaults or the loaded values.
		for i=1, table.getn(self.adjustMirror) do
			setRotation(self.adjustMirror[i].x1,math.min(0,self.adjustMirror[i].x0),0,0);
			setRotation(self.adjustMirror[i].x2,math.max(0,self.adjustMirror[i].x0),0,0);
			setRotation(self.adjustMirror[i].y1,0,0,math.max(0,self.adjustMirror[i].y0));
			setRotation(self.adjustMirror[i].y2,0,0,math.min(0,self.adjustMirror[i].y0));
		end;
	end;
	print("\tDone width mirror stream:")

end;

function AdjustableMirrors:writeStream(streamId, connection)

	print("Writing mirror stream:")

	if not connection:getIsServer() then
		print("\tServer:")

		---[[

		if table.getn(self.adjustMirror) > 0 then

			--Inform the client that we have mirror settings stored
			streamWriteBool(streamId, true)

			for i=1,table.getn(self.adjustMirror) do

				print(string.format("\t\tmirror%s",(i)))

				streamWriteUIntN(streamId, self.adjustMirror[i].x0 * (2^AdjustableMirrors.sendNumBits - 1), AdjustableMirrors.sendNumBits)
				streamWriteUIntN(streamId, self.adjustMirror[i].y0 * (2^AdjustableMirrors.sendNumBits - 1), AdjustableMirrors.sendNumBits)

				print(string.format("\t\t\trotx:%f\n\t\t\troty:%f",(self.adjustMirror[i].x0),(self.adjustMirror[i].y0)))

			end

		else
			--No mirror settings stored for this vehicle
			streamWriteBool(streamId, false)
			print("\tNo mirror settings stored for this vehicle")
		end

		--]]

	end;

	print("\tDone writing mirror stream")

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

	if g_server == nil then
		print("Leaving vehicle, sending event from client")
		AMUpdateEvent.sendEvent(false);
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


function AdjustableMirrors:onLeave()

	if g_server == nil then
		print("Leaving vehicle, sending event from client")
		AMUpdateEvent.sendEvent(true);
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
    local self = Event:new(AMUpdateEvent_mt);
    self.className = "AMUpdateEvent";
    return self;
end;

function AMUpdateEvent:new(checkValue)
    local self = AMUpdateEvent:emptyNew()
    self.checkValue = checkValue
	--Insert some code which inits some values

    --self.distance   = Utils.getNoNil(vehicle.modFM.FollowKeepBack, 0)
    --self.offset     = Utils.getNoNil(vehicle.modFM.FollowXOffset, 0)
    return self;
end;

function AMUpdateEvent:writeStream(streamId, connection)

	if g_server == nil then
		streamWriteBool(streamId, self.checkValue)
		print("Writing stream of event from client")
	else
		print("Would have written from the server")
	end
end;

function AMUpdateEvent:readStream(streamId, connection)

	if g_server ~= nil then
		print("Reading stream of event on server")
    	
		self.checkValue = streamReadBool(streamId)

		print(self.checkValue)

		--printTableRecursively(self.vehichle, '-', 0, 1)
	else
		print("Would have been reading on the client")
	end

	-- if not connection:getIsServer() then
	-- 	g_server:broadcastEvent(AMUpdateEvent:new(self.vehichle))
	-- end;

	

    -- if self.vehicle ~= nil then
    --     if     self.cmdId == FollowMe.COMMAND_START then
    --         FollowMe.startFollowMe(self.vehicle, connection)
    --     elseif self.cmdId == FollowMe.COMMAND_STOP then
    --         FollowMe.stopFollowMe(self.vehicle, self.reason)
    --     elseif self.cmdId == FollowMe.COMMAND_WAITRESUME then
    --         FollowMe.waitResumeFollowMe(self.vehicle, self.reason)
    --     else
    --         FollowMe.changeDistance(self.vehicle, { self.distance } )
    --         FollowMe.changeXOffset( self.vehicle, { self.offset } )
    --     end
    -- end;
end;

function AMUpdateEvent.sendEvent(checkValue)

	if g_server ~= nil then
		print("Server broadcasting event")
		g_server:broadcastEvent(AMUpdateEvent:new(checkValue), nil, nil, self);
	else
		print("Client requesting event")
		g_client:getServerConnection():sendEvent(AMUpdateEvent:new(checkValue));
	end;

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