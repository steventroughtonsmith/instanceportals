local IPUIDebug=false

function InstancePortalUI_OnLoad(self)
	LoadAddOn("Blizzard_WorldMap")
	self:RegisterEvent("ADDON_LOADED")

	IPUIPrintDebug("InstancePortalUI_OnLoad()")
	WorldMapFrame:AddDataProvider(CreateFromMixins(IPInstancePortalMapDataProviderMixin));
end

function IPUIPrintDebug(t)
	if (IPUIDebug) then
		print(t)
	end
end

function IPUIGetEntranceInfoForMapID(mapID, i)

		instancePortal = IPUIPinDB[mapID][i]
		if not (instancePortal) then
			IPUIPrintDebug("No instances for map: "..mapID)
			return nil
		end

		local x = instancePortal[1]/100
		local y = instancePortal[2]/100
		local subInstanceMapIDs = instancePortal[3]
		local hubName = instancePortal[4]

		if hubName then
			entranceInfo = {};

			entranceInfo["areaPoiID"] = C_AreaPoiInfo.GetAreaPOIForMap(mapID)[0];
			entranceInfo["position"] = CreateVector2D(x, y);
			entranceInfo["name"] = hubName;

			local description = "";

			for m = 1, #subInstanceMapIDs do
				local instanceID = subInstanceMapIDs[m]
				local localizedName = EJ_GetInstanceInfo(instanceID);
				local requiredLevel = IPUIInstanceMapDB[subInstanceMapIDs[m]][3]
				description = description..localizedName.." |cFF888888("..requiredLevel..")|r\n"
			end

			entranceInfo["description"] = description;
			entranceInfo["atlasName"] = "Raid";

			entranceInfo["journalInstanceID"] = 0;
			entranceInfo["hub"] = 1;

			IPUIPrintDebug("Hub: " .. entranceInfo["name"]);

			return entranceInfo
		end

		local m = 1
		if IPUIInstanceMapDB[subInstanceMapIDs[m]] then
			local name = IPUIInstanceMapDB[subInstanceMapIDs[m]][1]
			local type = IPUIInstanceMapDB[subInstanceMapIDs[m]][2]
			local requiredLevel = IPUIInstanceMapDB[subInstanceMapIDs[m]][3]
			local tier = IPUIInstanceMapDB[subInstanceMapIDs[m]][4]

			entranceInfo = {};

			entranceInfo["areaPoiID"] = C_AreaPoiInfo.GetAreaPOIForMap(mapID)[0];
			entranceInfo["position"] = CreateVector2D(x, y);
			if (type == 1) then
				entranceInfo["atlasName"] = "Dungeon";
				entranceInfo["description"] = "Dungeon";
			else
				entranceInfo["atlasName"] = "Raid";
				entranceInfo["description"] = "Raid";
			end

			EJ_SelectTier(tier)
			local instanceID = subInstanceMapIDs[m]

			local localizedName = EJ_GetInstanceInfo(instanceID);

			entranceInfo["name"] = localizedName.." |cFF888888("..requiredLevel..")|r";

			entranceInfo["journalInstanceID"] = instanceID;
			entranceInfo["tier"] = tier;
			entranceInfo["hub"] = 0;

			IPUIPrintDebug("Instance: " .. entranceInfo["name"].." id:"..instanceID);

			return entranceInfo
		end
end
