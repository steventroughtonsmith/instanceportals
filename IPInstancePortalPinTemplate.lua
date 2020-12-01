IPInstancePortalMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

function IPInstancePortalMapDataProviderMixin:RemoveAllData()
  self:GetMap():RemoveAllPinsByTemplate("IPInstancePortalPinTemplate");
end

function IPInstancePortalMapDataProviderMixin:OnShow()
  self:RegisterEvent("CVAR_UPDATE");
end

function IPInstancePortalMapDataProviderMixin:OnHide()
  self:UnregisterEvent("CVAR_UPDATE");
end

function IPInstancePortalMapDataProviderMixin:OnEvent(event, ...)
  if event == "CVAR_UPDATE" then
    local eventName, value = ...;
    if eventName == "INSTANCE_PORTAL_REFRESH" then
      self:RefreshAllData();
    end
  end
end

function IPInstancePortalMapDataProviderMixin:RefreshAllData(fromOnShow)
  self:RemoveAllData();
  IPUIPrintDebug("IPInstancePortalMapDataProviderMixin:RefreshAllData")

  local trackOnZones = IPUITrackInstancePortals
  local trackOnContinents = IPUITrackInstancePortalsOnContinents

  local mapID = self:GetMap():GetMapID();
  IPUIPrintDebug("Map ID = "..mapID)

  local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(mapID)

  for i, dungeonEntranceInfo in ipairs(dungeonEntrances) do
    IPUIPrintDebug("Atlas = ("..dungeonEntranceInfo["position"]["x"]..","..dungeonEntranceInfo["position"]["y"]..")")
  end

  if IPUIPinDB[mapID] then
    local count = #IPUIPinDB[mapID]
    local isContinent = false;
    for i = 1, #IPUIContinentMapDB do
      if IPUIContinentMapDB[i] == mapID then
        isContinent = true;
      end
    end

    if not (isContinent) then
      return
    end

    IPUIPrintDebug("Map is continent = "..(isContinent and 'true' or 'false'))
    local playerFaction = UnitFactionGroup("player")

    for i = 1, count do
      local entranceInfo = IPUIGetEntranceInfoForMapID(mapID, i);

      if entranceInfo then
        local factionWhitelist = entranceInfo["factionWhitelist"];

        local isWhitelisted = true;

        if factionWhitelist and not (factionWhitelist == playerFaction) then
          isWhitelisted = false
        end

        if (isContinent and trackOnContinents) or (not isContinent and trackOnZones) then
          if (isWhitelisted) then
            self:GetMap():AcquirePin("IPInstancePortalPinTemplate", entranceInfo);
          end
        end
      end
    end
  end

end

--[[ Pin ]]--
IPInstancePortalProviderPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_DUNGEON_ENTRANCE");

function IPInstancePortalProviderPinMixin:OnAcquired(dungeonEntranceInfo) -- override
  BaseMapPoiPinMixin.OnAcquired(self, dungeonEntranceInfo);

  self.hub = dungeonEntranceInfo.hub
  self.tier = dungeonEntranceInfo.tier;
  self.journalInstanceID = dungeonEntranceInfo.journalInstanceID;
end

-- local function for "Add Waypoints" with the feature to "force" Built-In Waypoint System, just set "useTomTom" to false or leave it blank
local function AddWaypoint(mapID, x, y, title, useTomTom)
  if (useTomTom == true) and TomTom then
    title = title or "Waypoint"
    TomTom:AddWaypoint(mapID, x, y, {
      title = title,
      persistent = false,
      minimap = true,
      world = true,
      from = "InstancePortals"
    })
  else -- if TomTom is not installed or useTomTom is false you the Built-In Waypoint System
    if C_Map.CanSetUserWaypointOnMap(mapID) then
      local vector = CreateVector2D(x, y)
      local mapPoint = UiMapPoint.CreateFromVector2D(mapID, vector)
      C_Map.SetUserWaypoint(mapPoint)
      local shouldSuperTrack = not C_SuperTrack.IsSuperTrackingUserWaypoint();
      C_SuperTrack.SetSuperTrackedUserWaypoint(shouldSuperTrack)
      if shouldSuperTrack then
        PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON, nil, SOUNDKIT_ALLOW_DUPLICATES);
      else
        PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_OFF, nil, SOUNDKIT_ALLOW_DUPLICATES);
      end
    end
  end
end

function IPInstancePortalProviderPinMixin:OnClick(button)
  local useWaypoints = true
  local useTomTom = true
  local wp_mapid, wp_x, wp_y, wp_name
  useTomTom = useTomTom and (TomTom ~= nil) or false

  if self.hub == 0 then
    if ((button == "RightButton") and (useWaypoints == true)) then
      local uiMapID = self:GetMap():GetMapID();
      if not uiMapID then return end
      local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) -- get current map children
      if ( (type(mapChildren) ~= 'table') or (#mapChildren < 1) ) then return end -- mapChildren is not table or empty
      local journalInstanceID = self.journalInstanceID
      if not journalInstanceID then return end

      for _, childMapInfo in ipairs(mapChildren) do -- enum "current" map for children
        if childMapInfo then
          local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(childMapInfo.mapID); -- get Dungeon Entrances for current Map
          for _, dungeonEntranceInfo in ipairs(dungeonEntrances) do -- enum "dungeonEntrances"
            if dungeonEntranceInfo.journalInstanceID == journalInstanceID then -- found Dungeon with matching instanceID
              wp_mapid = childMapInfo.mapID
              wp_x = dungeonEntranceInfo.position.x
              wp_y = dungeonEntranceInfo.position.y
              wp_name = dungeonEntranceInfo.name or "Waypoint"
						end
          end
				end
      end

      
      if (not wp_mapid) then -- if no "Dungeon Entrance" is found, try to use Map Pin itself as Source
        wp_mapid = self:GetMap():GetMapID();
        wp_x, wp_y = self:GetPosition()
        wp_name = self.name or "Waypoint"
      end
    else -- not "RightButton" or "useWaypoints" is false then just open Encounter Journal
      EncounterJournal_LoadUI();
      EncounterJournal_OpenJournal(nil, self.journalInstanceID)
    end
  else -- if self.hub ~= 0, try to use Map Pin itself as Source
    if ((button == "RightButton") and (useWaypoints == true)) then
      wp_mapid = self:GetMap():GetMapID();
      wp_x, wp_y = self:GetPosition()
      wp_name = self.name or "Waypoint"
    end
  end

	-- check for all needed Variables and Add Waypoint if all Variables are present
  if ((button == "RightButton") and (useWaypoints == true)) and wp_mapid and wp_x and wp_y and wp_name then
    AddWaypoint(wp_mapid, wp_x, wp_y, wp_name, useTomTom)
  end
end