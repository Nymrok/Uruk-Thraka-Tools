-- ============================================================================
-- Page Développement
-- ============================================================================
local addonName, addon = ...
addon.Displayer = addon.Displayer or {}
addon.Displayer.Development = {}
addon.Displayer.Development.header = "Développement"

function addon.Displayer.Development:CreateContent(displayFrame)
    local titleText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", 20, -20)
    titleText:SetText("|cffffd700Outils de développement|r")
    titleText:SetTextColor(1, 1, 1, 1)
    titleText:SetJustifyH("LEFT")

    local btn = addon.ButtonTemplates.CreateHD_Btn_RedGrey_Stretch(displayFrame, "Analyser la zone")
    btn:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -15)
    btn:SetScript("OnClick", function()
        -- Informations de base sur la zone
        local mapID = C_Map.GetBestMapForUnit("player")
        local mapInfo = mapID and C_Map.GetMapInfo(mapID)
        if mapInfo then
            -- Conversion du type de zone en nom lisible
            local mapTypeNames = {
                [0] = "Cosmic",
                [1] = "World", 
                [2] = "Continent",
                [3] = "Zone",
                [4] = "Dungeon",
                [5] = "Micro",
                [6] = "Orphan"
            }
            local mapType = mapInfo.mapType or 0
            local mapTypeName = mapTypeNames[mapType] or "Inconnu"
            
            -- Informations sur la zone parent
            local parentInfo = ""
            if mapInfo.parentMapID then
                local parentMapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
                local parentName = parentMapInfo and parentMapInfo.name or "Inconnu"
                parentInfo = ", " .. parentName .. " (" .. mapInfo.parentMapID .. ")"
            end
            
            -- Affichage du résumé compact
            print(mapTypeName .. " (" .. mapType .. ") : " .. mapInfo.name .. " (" .. mapID .. ")" .. parentInfo)
        end
        
        -- Informations sur la sous-zone actuelle
        local subZone = GetSubZoneText()
        local zone = GetZoneText()
        local realZone = GetRealZoneText()
        print("Zone principale:", zone)
        print("Sous-zone:", subZone ~= "" and subZone or "Aucune")
        print("Zone réelle:", realZone)
        
        -- Informations sur l'instance
        local inInstance, instanceType = IsInInstance()
        if inInstance then
            local name, type, difficulty, difficultyName, maxPlayers, playerDifficulty, isDynamicInstance = GetInstanceInfo()
            print("=== INSTANCE ===")
            print("Nom:", name)
            print("Type:", type)
            print("Difficulté:", difficultyName)
            print("Joueurs max:", maxPlayers)
            print("Dynamique:", isDynamicInstance and "Oui" or "Non")
        end
        
        -- Informations sur la guilde et communauté
        local guildMapID = C_Map.GetMapForUnit and C_Map.GetMapForUnit("player")
        if guildMapID then
            print("Map ID guilde:", guildMapID)
        end
        
        -- Zone de guerre (War Mode specific)
        if C_PvP.IsWarModeActive() then
            local bounty = C_PvP.GetWarModeBountyReward()
            if bounty and bounty > 0 then
                print("Prime War Mode:", bounty .. "%")
            end
        end
        
        -- Informations supplémentaires sur la carte
        local mapChildren = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone)
        if mapChildren and #mapChildren > 0 then
            print("Sous-zones disponibles:", #mapChildren)
            for i, childInfo in ipairs(mapChildren) do
                if childInfo and childInfo.name and childInfo.mapID then
                    print("  - " .. childInfo.name .. " (ID: " .. childInfo.mapID .. ")")
                end
            end
        end
    end)

    local expeditionsBtn = addon.ButtonTemplates.CreateHD_Btn_RedGrey_Stretch(displayFrame, "Scanner toutes les expéditions")
    expeditionsBtn:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -10)
    expeditionsBtn:SetScript("OnClick", function()
        print("=== SCAN COMPLET DES EXPEDITIONS DISPONIBLES ===")
        
        -- Zones d'expéditions à scanner (même liste que dans ExpeditionsService)
        local SCAN_ZONES = {
            -- Kalimdor
            62,   -- Sombrivage
            
            -- Royaumes de l'Est
            14,   -- Hautes-terres Arathies
            
            -- Îles Brisées
            630,  -- Azsuna
            641,  -- Val'sharah
            650,  -- Haut-Roc
            634,  -- Tornheim
            680,  -- Suramar
            790,  -- L'Oeil d'Azshara
            646,  -- Rivage Brisé
            830,  -- Krokuun
            882,  -- Érédath
            885,  -- Étendues Antoréennes
            
            -- Zandalar
            864,  -- Vol'dun
            863,  -- Nazmir
            862,  -- Zuldazar
            
            -- Kul Tiras
            896,  -- Drustvar
            942,  -- Vallée Chantorage
            1462, -- Île de Mécagone
            895,  -- Rade de Tiragarde
            1161, -- Boralus
            
            -- Nazjatar
            1355, -- Nazjatar
            
            -- Île aux Dragons
            2022, -- Rivages de l'Éveil
            2023, -- Plaines d'Ohn'ahra
            2024, -- Travée d'Azur
            2025, -- Thaldraszus
            2151, -- Confins Interdits
            2133, -- Grotte de Zaralek
            2200, -- Rêve d'émeraude
            
            -- Khaz Algar
            2248, -- Île de Dorn
            2215, -- Sainte-Chute
            2255, -- Azj'Kahet
            2369, -- Île aux Sirènes
            2371, -- K'aresh
            2214, -- Les abîmes Retentissants
            2346, -- Terremine
            
            -- Ombreterre
            1525, -- Revendreth
            1565, -- Sylvarden
            1533, -- Le Bastion
            1536, -- Maldraxxus
            1970, -- Zereth Mortis
            1543, -- Antre
        }
        
        local foundExpeditions = {}
        local totalExpeditions = 0
        local scannedZones = 0
        
        for _, mapID in ipairs(SCAN_ZONES) do
            local mapInfo = C_Map.GetMapInfo(mapID)
            local mapName = mapInfo and mapInfo.name or ("Zone " .. mapID)
            
            local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
            if quests and #quests > 0 then
                local zoneExpeditions = {}
                
                for _, quest in ipairs(quests) do
                    if quest.questID then
                        local isWorldQuest = C_QuestLog.IsWorldQuest(quest.questID)
                        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(quest.questID)
                        
                        -- Seulement les World Quests non terminées
                        if isWorldQuest and not isCompleted then
                            local questInfo = C_TaskQuest.GetQuestInfoByQuestID(quest.questID)
                            local questName = questInfo or ("Expédition " .. quest.questID)
                            
                            table.insert(zoneExpeditions, {
                                id = quest.questID,
                                name = questName
                            })
                            totalExpeditions = totalExpeditions + 1
                        end
                    end
                end
                
                if #zoneExpeditions > 0 then
                    foundExpeditions[mapID] = {
                        mapName = mapName,
                        expeditions = zoneExpeditions
                    }
                end
            end
            scannedZones = scannedZones + 1
        end
        
        print("Zones scannées:", scannedZones)
        print("Total expéditions disponibles:", totalExpeditions)
        print("")
        
        if totalExpeditions > 0 then
            for mapID, zoneData in pairs(foundExpeditions) do
                print("|cffFFD700" .. zoneData.mapName .. " (" .. mapID .. ")|r")
                for _, expedition in ipairs(zoneData.expeditions) do
                    print("  |cff87CEEB- " .. expedition.name .. " (ID: " .. expedition.id .. ")|r")
                end
                print("")
            end
        else
            print("|cffFF6B6BAucune expédition disponible actuellement.|r")
        end
        
        print("=========================================")
    end)

    if addon.Display and addon.Display.UpdateContentHeight then
        C_Timer.After(0.1, function()
            addon.Display:UpdateContentHeight()
        end)
    end
end