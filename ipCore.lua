local IPUI_ICON_COORDS_DUNGEON = {0,0.242,0,0.242}
local IPUI_ICON_COORDS_RAID = {0.242,0.484,0,0.242}
local IPUI_ICON_COORDS_DUNGEON_HIGHLIGHTED = {0,0.242,0.242,0.484}
local IPUI_ICON_COORDS_RAID_HIGHLIGHTED = {0.242,0.484,0.242,0.484}

local IPUI_ICON_COORDS_HUB = IPUI_ICON_COORDS_DUNGEON
local IPUI_ICON_COORDS_HUB_HIGHLIGHTED = IPUI_ICON_COORDS_DUNGEON_HIGHLIGHTED

local IPUIPinFrames = {}
local IPUIMapTooltip = nil
local IPUIDungeonTable = {}

local IPUIDebug=false

function InstancePortalUI_OnLoad(self)
	self:RegisterForDrag("LeftButton")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("WORLD_MAP_UPDATE")
	self:RegisterEvent("WORLD_MAP_NAME_UPDATE")
	self:SetScript("OnEvent", IPUIEventHandler)

	IPUIPrintDebug("InstancePortalUI_OnLoad()")

	IPUIMapTooltipSetup()
end

function IPUIPrintDebug(t)
	if (IPUIDebug) then
		print(t)
	end
end

function IPUIHideAllPins()
	for i = 1, #IPUIPinFrames do
		IPUIPinFrames[i]:Hide()
		--table.remove(IPUIPinFrames,i)
	end

	wipe(IPUIPinFrames)
end

function IPUIRefreshPins()
	IPUIHideAllPins()
	if not (WorldMapFrame:IsVisible()) then return nil end

	local cityOverride = false

	if ((GetCurrentMapAreaID() == 301) or (GetCurrentMapAreaID() == 321) or (GetCurrentMapAreaID() == 504)) then
		cityOverride = true
	end

	IPUIPrintDebug("IPUIRefreshPins for map: "..GetCurrentMapAreaID())

	if ((GetCurrentMapDungeonLevel() == 0) or cityOverride) then
		for i = 1, #IPUIPinDB[GetCurrentMapAreaID()] do
			IPUIShowPin(i)
		end
	else
		IPUIPrintDebug("No pins for this dungeon level")
	end
end

function IPUIMapTooltipSetup()
	IPUIMapTooltip = CreateFrame("GameTooltip", "IPUIMapTooltip", WorldFrame, "GameTooltipTemplate")
	IPUIMapTooltip:SetFrameStrata("TOOLTIP")
	WorldMapFrame:HookScript("OnSizeChanged",
		function(self)
			IPUIMapTooltip:SetScale(1/self:GetScale())
		end
	)
end

function IPUIShowPin(locationIndex) --x, y, type)
	instancePortal = IPUIPinDB[GetCurrentMapAreaID()][locationIndex]

	if not (instancePortal) then
		IPUIPrintDebug("No pin "..locationIndex.." for map: "..GetCurrentMapAreaID())
		return nil
	end

	local x = instancePortal[1]
	local y = instancePortal[2]

	local subInstanceMapIDs = instancePortal[3]

	local type = IPUIInstanceMapDB[subInstanceMapIDs[1]][2]

	local pin = CreateFrame("Frame", "IPPin", WorldMapDetailFrame)

	pin.Texture = pin:CreateTexture()
	pin.Texture:SetTexture("Interface\\Addons\\InstancePortals\\Images\\IPIcons")
	pin.Texture:SetAllPoints()
	pin:EnableMouse(true)
	pin:SetFrameStrata("HIGH")
	pin:SetFrameLevel(WorldMapFrame.UIElementsFrame:GetFrameLevel())

	pin:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", (x / 100) * WorldMapDetailFrame:GetWidth(), (-y / 100) * WorldMapDetailFrame:GetHeight())

	pin:SetWidth(31)
	pin:SetHeight(31)
	if (type == 1) then
		pin.Texture:SetTexCoord(unpack(IPUI_ICON_COORDS_DUNGEON))
	elseif (type == 2) then
		pin.Texture:SetTexCoord(unpack(IPUI_ICON_COORDS_RAID))
	end

	if (#subInstanceMapIDs > 1) then
		pin.Texture:SetTexCoord(unpack(IPUI_ICON_COORDS_HUB))
	end

	pin:HookScript("OnEnter",
			function(pin, motion)

				if (type == 1) then
					pin.Texture:SetTexCoord(unpack(IPUI_ICON_COORDS_DUNGEON_HIGHLIGHTED))
				elseif (type == 2) then
					pin.Texture:SetTexCoord(unpack(IPUI_ICON_COORDS_RAID_HIGHLIGHTED))
				end

				IPUIMapTooltip:SetOwner(pin, "ANCHOR_RIGHT")
				IPUIMapTooltip:ClearLines()
				IPUIMapTooltip:SetScale(GetCVar("uiScale"))
				if (#subInstanceMapIDs > 1) then
					IPUIMapTooltip:AddLine("Hub")
				end
					for i = 1, #subInstanceMapIDs do
						local name = IPUIInstanceMapDB[subInstanceMapIDs[i]][1]
						local type = IPUIInstanceMapDB[subInstanceMapIDs[i]][2]
						local requiredLevel = IPUIInstanceMapDB[subInstanceMapIDs[i]][3]

						IPUIMapTooltip:AddDoubleLine(string.format("|cffffffff%s|r",name), string.format("|cffff7d0a[%d]|r", requiredLevel))
						if (type == 1) then
							IPUIMapTooltip:AddTexture("Interface\\Addons\\InstancePortals\\Images\\IPDungeon")
						else
							IPUIMapTooltip:AddTexture("Interface\\Addons\\InstancePortals\\Images\\IPRaid")
						end
					end


				IPUIMapTooltip:Show()
			end
	)
	pin:HookScript("OnLeave",
			function(pin)
				if (type == 1) then
					pin.Texture:SetTexCoord(unpack(IPUI_ICON_COORDS_DUNGEON))
				elseif (type == 2) then
					pin.Texture:SetTexCoord(unpack(IPUI_ICON_COORDS_RAID))
				end
				IPUIMapTooltip:Hide()
			end
		)
	pin:HookScript("OnMouseDown",
			function(self, button)
				if (button == "LeftButton") then
					if (#subInstanceMapIDs == 1) then
						SetMapByID(subInstanceMapIDs[1])
					end
				end
			end
		)
	table.insert(IPUIPinFrames, pin)
	pin:Show()
end

function IPUIEventHandler(self, event, ...)
	IPUIRefreshPins()
end