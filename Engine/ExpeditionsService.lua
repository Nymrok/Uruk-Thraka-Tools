-- ============================================================================
-- Service centralisé pour la gestion et surveillance des expéditions
-- Surveillance basée sur les événements WoW (pas de timers pour les performances)
-- Événements déclencheurs : PLAYER_ENTERING_WORLD, ZONE_CHANGED_NEW_AREA
-- ============================================================================

local addonName, addon = ...

addon.ExpeditionsService = addon.ExpeditionsService or {}

-- ============================================================================
-- ÉTAT PRIVÉ
-- ============================================================================
local isEnabled = false -- true / false || Service : Activé / Désactivé
local availableCache = {}
local callbacks = {
    onAvailable = {}, -- {questID, questName} || Quand une expédition devient disponible
    onUnavailable = {}, -- {questID, questName} || Quand une expédition n'est plus disponible
    onChange = {}
}

-- Frame pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- Zones d'expéditions précises basées sur la hiérarchie cartographique complète
addon.ExpeditionsService.SCAN_ZONES = {
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

-- ============================================================================
-- UTILITAIRES PRIVÉS
-- ============================================================================

--[[
    S'assure que les données de sauvegarde existent
]]
local function ensureData()
    addon:EnsureUTTData()
    UTT_Data.ExpeditionsMonitored = UTT_Data.ExpeditionsMonitored or {}
    UTT_Data.expeditionsServiceEnabled = UTT_Data.expeditionsServiceEnabled or false
end

--[[
    Récupère le nom d'une expédition à partir de son ID
]]
local function getQuestName(questID)
    local name = C_TaskQuest.GetQuestInfoByQuestID(questID)
    return name and name ~= "" and name or ("Expédition " .. questID)
end

--[[
    Vérifie si une expédition est actuellement disponible
    @param questID number - L'ID de l'expédition
    @return boolean - true si l'expédition est disponible
]]
local function isQuestAvailable(questID)
    -- Scanner les zones spécifiques pour trouver la quête
    for _, mapID in ipairs(addon.ExpeditionsService.SCAN_ZONES) do
        local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
        if quests then
            for _, quest in ipairs(quests) do
                -- Vérifier l'ID de quête exact
                if quest.questID == questID then
                    -- STRICTEMENT vérifier que c'est une World Quest active ET non terminée
                    local isWorldQuest = C_QuestLog.IsWorldQuest(quest.questID)
                    local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(quest.questID)
                    
                    -- SEULEMENT si c'est une WorldQuest ET qu'elle n'est PAS terminée
                    if isWorldQuest and not isCompleted then
                        return true
                    end
                end
            end
        end
    end
    
    -- Si pas trouvé dans les zones habituelles, essayer une recherche exhaustive rapide
    -- (seulement pour les zones TWW récentes 2500-2700)
    for testMapID = 2500, 2700 do
        local quests = C_TaskQuest.GetQuestsForPlayerByMapID(testMapID)
        if quests then
            for _, quest in ipairs(quests) do
                if quest.questID == questID then
                    local isWorldQuest = C_QuestLog.IsWorldQuest(quest.questID)
                    local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(quest.questID)
                    
                    if isWorldQuest and not isCompleted then
                        -- Ajouter cette zone aux zones de scan pour éviter les futures recherches
                        local alreadyInScan = false
                        for _, existingMapID in ipairs(addon.ExpeditionsService.SCAN_ZONES) do
                            if existingMapID == testMapID then
                                alreadyInScan = true
                                break
                            end
                        end
                        
                        if not alreadyInScan then
                            table.insert(addon.ExpeditionsService.SCAN_ZONES, testMapID)
                            local mapInfo = C_Map.GetMapInfo(testMapID)
                            print("[UTT] Zone auto-ajoutée : " .. testMapID .. " (" .. (mapInfo and mapInfo.name or "Inconnue") .. ")")
                        end
                        
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

--[[
    Scanne toutes les expéditions surveillées pour vérifier leur disponibilité
    Déclenché par les événements : PLAYER_ENTERING_WORLD, ZONE_CHANGED_NEW_AREA
]]
local function scanAvailableExpeditions()
    if not isEnabled then return end
    
    ensureData()
    local newAvailable = {} -- Table vide, on va la repeupler complètement
    local changes = false
    
    -- Scanner toutes les expéditions surveillées
    for questID, data in pairs(UTT_Data.ExpeditionsMonitored) do
        questID = tonumber(questID) -- S'assurer que c'est un nombre
        
        if isQuestAvailable(questID) then
            newAvailable[questID] = true
            
            -- Nouvelle expédition disponible
            if not availableCache[questID] then
                changes = true
                for _, callback in ipairs(callbacks.onAvailable) do
                    pcall(callback, questID, data.name)
                end
            end
        else
            -- Expédition plus disponible  
            if availableCache[questID] then
                changes = true
                for _, callback in ipairs(callbacks.onUnavailable) do
                    pcall(callback, questID, data.name)
                end
            end
        end
    end
    
    -- CRUCIAL : Remplacer complètement le cache plutôt que de le mettre à jour partiellement
    availableCache = newAvailable
    
    -- Notifier les changements
    if changes then
        for _, callback in ipairs(callbacks.onChange) do
            pcall(callback)
        end
    end
end

--[[
    Gestionnaire d'événements pour la surveillance des expéditions
]]
local function onEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Première connexion ou rechargement d'interface
        if isEnabled then
            -- Délai pour laisser le jeu charger complètement
            C_Timer.After(2, scanAvailableExpeditions)
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- Changement de zone
        if isEnabled then
            -- Délai court pour laisser les données de zone se charger
            C_Timer.After(0.5, scanAvailableExpeditions)
        end
    end
end

--[[
    Démarre la surveillance basée sur les événements
]]
local function startEventScanning()
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:SetScript("OnEvent", onEvent)
    
    -- Scan initial si déjà en jeu
    C_Timer.After(1, scanAvailableExpeditions)
end

--[[
    Arrête la surveillance basée sur les événements
]]
local function stopEventScanning()
    eventFrame:UnregisterAllEvents()
    eventFrame:SetScript("OnEvent", nil)
    availableCache = {}
end

-- ============================================================================
-- API PUBLIQUE
-- ============================================================================

--[[
    Vérifie si le service est activé
    @return boolean - true si activé
]]
function addon.ExpeditionsService:IsEnabled()
    return isEnabled
end

--[[
    Active le service de surveillance
]]
function addon.ExpeditionsService:Enable()
    ensureData()
    isEnabled = true
    UTT_Data.expeditionsServiceEnabled = true
    startEventScanning()
    
    -- Déclencher les callbacks pour mettre à jour l'interface
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
end

--[[
    Désactive le service de surveillance
]]
function addon.ExpeditionsService:Disable()
    ensureData()
    isEnabled = false
    UTT_Data.expeditionsServiceEnabled = false
    stopEventScanning()
    
    -- Déclencher les callbacks pour mettre à jour l'interface
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
end

--[[
    Ajoute une expédition à surveiller
    @param questID number|string - L'ID de l'expédition
    @return boolean, string - Succès et message
]]
function addon.ExpeditionsService:Add(questID)
    if not questID or not tonumber(questID) then
        return false, "ID invalide"
    end
    
    questID = tonumber(questID)
    
    -- Vérification plus flexible : essayer de récupérer des informations sur la quête
    local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
    
    -- Si on ne peut pas récupérer d'infos ET que ce n'est pas une WorldQuest, alors c'est invalide
    if not questName and not C_QuestLog.IsWorldQuest(questID) then
        return false, "Cet ID ne correspond pas à une expédition valide"
    end
    
    ensureData()
    
    -- Vérifier si déjà surveillée
    if UTT_Data.ExpeditionsMonitored[questID] then
        return false, "Expédition déjà surveillée"
    end
    
    local name = questName or getQuestName(questID)
    UTT_Data.ExpeditionsMonitored[questID] = {
        id = questID,
        name = name,
        addedAt = time()
    }
    
    -- Notifier les changements
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
    
    -- Scanner immédiatement pour cette expédition
    if isEnabled then
        C_Timer.After(1, scanAvailableExpeditions)
    end
    
    return true, "Expédition ajoutée : " .. name
end

--[[
    Supprime une expédition de la surveillance
    @param questID number - L'ID de l'expédition
    @return boolean, string - Succès et message
]]
function addon.ExpeditionsService:Remove(questID)
    if not questID then 
        return false, "ID manquant"
    end
    
    ensureData()
    questID = tonumber(questID)
    local data = UTT_Data.ExpeditionsMonitored[questID]
    
    if not data then 
        return false, "Expédition non surveillée"
    end
    
    UTT_Data.ExpeditionsMonitored[questID] = nil
    availableCache[questID] = nil
    
    -- Notifier les changements
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
    
    return true, "Expédition supprimée : " .. data.name
end

--[[
    Récupère toutes les expéditions surveillées
    @return table - Table des expéditions surveillées
]]
function addon.ExpeditionsService:GetMonitored()
    ensureData()
    return UTT_Data.ExpeditionsMonitored or {}
end

--[[
    Récupère les expéditions actuellement disponibles
    @return table - Table des expéditions disponibles
]]
function addon.ExpeditionsService:GetAvailable()
    return availableCache
end

--[[
    Compte le nombre d'expéditions disponibles
    @return number - Nombre d'expéditions disponibles
]]
function addon.ExpeditionsService:GetAvailableCount()
    local count = 0
    for _ in pairs(availableCache) do
        count = count + 1
    end
    return count
end

--[[
    Vérifie si une expédition spécifique est disponible
    @param questID number - L'ID de l'expédition
    @return boolean - true si disponible
]]
function addon.ExpeditionsService:IsAvailable(questID)
    return availableCache[tonumber(questID)] == true
end

--[[
    Force un scan immédiat des expéditions
]]
function addon.ExpeditionsService:ForceScan()
    if isEnabled then
        scanAvailableExpeditions()
    end
end

--[[
    Recherche exhaustive d'une expédition dans toutes les zones possibles
    et met à jour automatiquement SCAN_ZONES si nécessaire
    @param questID number - L'ID de l'expédition à chercher
    @return table - Résultats de la recherche
]]
function addon.ExpeditionsService:FindQuest(questID)
    if not questID then return nil end
    
    questID = tonumber(questID)
    local results = {
        questID = questID,
        found = false,
        foundZones = {},
        newZones = {}
    }
    
    -- D'abord vérifier dans les zones existantes
    for _, mapID in ipairs(addon.ExpeditionsService.SCAN_ZONES) do
        local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
        if quests then
            for _, quest in ipairs(quests) do
                if quest.questID == questID then
                    results.found = true
                    table.insert(results.foundZones, mapID)
                end
            end
        end
    end
    
    -- Si pas trouvé, recherche exhaustive dans les zones 2000-2700
    if not results.found then
        for testMapID = 2000, 2700 do
            local quests = C_TaskQuest.GetQuestsForPlayerByMapID(testMapID)
            if quests then
                for _, quest in ipairs(quests) do
                    if quest.questID == questID then
                        results.found = true
                        table.insert(results.foundZones, testMapID)
                        
                        -- Vérifier si cette zone n'est pas déjà dans SCAN_ZONES
                        local alreadyInScan = false
                        for _, existingMapID in ipairs(addon.ExpeditionsService.SCAN_ZONES) do
                            if existingMapID == testMapID then
                                alreadyInScan = true
                                break
                            end
                        end
                        
                        if not alreadyInScan then
                            table.insert(results.newZones, testMapID)
                            -- Ajouter automatiquement à SCAN_ZONES pour les futurs scans
                            table.insert(addon.ExpeditionsService.SCAN_ZONES, testMapID)
                            local mapInfo = C_Map.GetMapInfo(testMapID)
                            print("[UTT] Nouvelle zone ajoutée au scan : " .. testMapID .. " (" .. (mapInfo and mapInfo.name or "Inconnue") .. ")")
                        end
                    end
                end
            end
        end
    end
    
    return results
end

--[[
    Vide le cache et force un rescan complet
]]
function addon.ExpeditionsService:ClearCache()
    availableCache = {}
    if isEnabled then
        C_Timer.After(0.5, scanAvailableExpeditions)
    end
    
    -- Notifier les changements
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
end

--[[
    Fonction de diagnostic pour débugger les expéditions
    @param questID number - L'ID de l'expédition à diagnostiquer (optionnel)
]]
function addon.ExpeditionsService:Debug(questID)
    local results = {
        timestamp = date("%Y-%m-%d %H:%M:%S"),
        serviceEnabled = isEnabled,
        monitoredCount = 0,
        availableCount = 0,
        currentMapID = C_Map.GetBestMapForUnit("player"),
        allZones = {},
        worldQuests = {}
    }
    
    -- Compter les expéditions surveillées
    ensureData()
    for id, data in pairs(UTT_Data.ExpeditionsMonitored) do
        results.monitoredCount = results.monitoredCount + 1
    end
    
    -- Compter les expéditions disponibles
    for id, _ in pairs(availableCache) do
        results.availableCount = results.availableCount + 1
    end
    
    -- Tester toutes les zones
    for _, mapID in ipairs(addon.ExpeditionsService.SCAN_ZONES) do
        local mapInfo = C_Map.GetMapInfo(mapID)
        local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
        local questCount = quests and #quests or 0
        
        results.allZones[mapID] = {
            mapName = mapInfo and mapInfo.name or "Inconnue",
            questCount = questCount
        }
        
        if quests and questID then
            for _, quest in ipairs(quests) do
                if quest.questID == questID then
                    results.foundQuestInZone = mapID
                    results.foundQuestMapName = mapInfo and mapInfo.name or "Inconnue"
                end
            end
        end
    end
    
    -- Si un questID spécifique est fourni, faire des tests détaillés
    if questID then
        results.questID = questID
        results.isWorldQuest = C_QuestLog.IsWorldQuest(questID)
        results.questInfo = C_TaskQuest.GetQuestInfoByQuestID(questID)
        results.isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)
        results.isAvailableByFunction = isQuestAvailable(questID)
        results.isInCache = availableCache[questID] == true
        
        -- Recherche détaillée dans toutes les zones
        results.foundInZones = {}
        for _, mapID in ipairs(addon.ExpeditionsService.SCAN_ZONES) do
            local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
            if quests then
                for _, quest in ipairs(quests) do
                    if quest.questID == questID then
                        local mapInfo = C_Map.GetMapInfo(mapID)
                        table.insert(results.foundInZones, {
                            mapID = mapID,
                            mapName = mapInfo and mapInfo.name or "Inconnue",
                            questMapID = quest.mapID,
                            isWorldQuest = C_QuestLog.IsWorldQuest(quest.questID),
                            isCompleted = C_QuestLog.IsQuestFlaggedCompleted(quest.questID),
                            hasCoordinates = quest.x and quest.y and true or false
                        })
                    end
                end
            end
        end
        
        -- RECHERCHE EXHAUSTIVE : Tester une gamme élargie de zones si pas trouvé
        if #results.foundInZones == 0 then
            results.exhaustiveSearch = {}
            -- Tester les zones 2000-2700 (toutes les zones récentes potentielles)
            for testMapID = 2000, 2700 do
                local quests = C_TaskQuest.GetQuestsForPlayerByMapID(testMapID)
                if quests then
                    for _, quest in ipairs(quests) do
                        if quest.questID == questID then
                            local mapInfo = C_Map.GetMapInfo(testMapID)
                            table.insert(results.exhaustiveSearch, {
                                mapID = testMapID,
                                mapName = mapInfo and mapInfo.name or ("Zone " .. testMapID),
                                questMapID = quest.mapID,
                                isWorldQuest = C_QuestLog.IsWorldQuest(quest.questID),
                                isCompleted = C_QuestLog.IsQuestFlaggedCompleted(quest.questID)
                            })
                        end
                    end
                end
            end
        end
    end
    
    -- Scanner les world quests de la zone actuelle
    if results.currentMapID then
        local currentZoneQuests = C_TaskQuest.GetQuestsForPlayerByMapID(results.currentMapID)
        if currentZoneQuests then
            for _, questInfo in ipairs(currentZoneQuests) do
                table.insert(results.worldQuests, {
                    questID = questInfo.questID,
                    mapID = questInfo.mapID,
                    isWorldQuest = C_QuestLog.IsWorldQuest(questInfo.questID),
                    isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questInfo.questID)
                })
            end
        end
    end
    
    return results
end

-- ============================================================================
-- SYSTÈME DE CALLBACKS
-- ============================================================================

--[[
    Enregistre un callback pour les expéditions qui deviennent disponibles
    @param callback function - Fonction appelée avec (questID, questName)
]]
function addon.ExpeditionsService:OnAvailable(callback)
    if type(callback) == "function" then
        table.insert(callbacks.onAvailable, callback)
    end
end

--[[
    Enregistre un callback pour les expéditions qui deviennent indisponibles
    @param callback function - Fonction appelée avec (questID, questName)
]]
function addon.ExpeditionsService:OnUnavailable(callback)
    if type(callback) == "function" then
        table.insert(callbacks.onUnavailable, callback)
    end
end

--[[
    Enregistre un callback pour tous changements de la liste
    @param callback function - Fonction appelée sans paramètres
]]
function addon.ExpeditionsService:OnChange(callback)
    if type(callback) == "function" then
        table.insert(callbacks.onChange, callback)
    end
end

-- ============================================================================
-- INITIALISATION
-- ============================================================================

--[[
    Initialise le service
]]
function addon.ExpeditionsService:Init()
    ensureData()
    isEnabled = UTT_Data.expeditionsServiceEnabled or false
    
    if isEnabled then
        startEventScanning()
    end
end
