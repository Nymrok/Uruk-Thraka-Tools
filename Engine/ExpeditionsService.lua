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
local isEnabled = false
local monitoredCache = {}
local availableCache = {}
local callbacks = {
    onAvailable = {},
    onUnavailable = {},
    onChange = {}
}

-- Frame pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- Zones de scan optimisées pour les extensions récentes (ajout de toutes les zones TWW)
local SCAN_ZONES = {
    -- The War Within (toutes les zones connues)
    2248, -- Isle of Dorn
    2339, -- Dornogal  
    2214, -- The Ringing Deeps
    2215, -- Hallowfall
    2255, -- Azj-Kahet
    2256, -- The City of Threads
    2213, -- Nerub'ar Palace
    2274, -- Khaz Algar
    2216, -- Ara-Kara, City of Echoes
    2217, -- The Dawnbreaker
    2267, -- The Stonevault
    2269, -- City of Threads
    2270, -- Ara-Kara
    2271, -- The Dawnbreaker  
    2272, -- Mists of Tirna Scithe
    2273, -- The Necrotic Wake
    2275, -- Sanguine Depths
    2276, -- Spires of Ascension
    2277, -- Theater of Pain
    2278, -- De Other Side
    2279, -- Halls of Atonement
    2280, -- Plaguefall
    2346, -- Zone Terremine découverte
    -- Dragonflight  
    2022, 2023, 2024, 2025, 2112, 2151,
    2200, 2133, 2134, 2135, 2136, 2137, -- Zones Dragonflight supplémentaires
    -- Shadowlands
    1533, 1525, 1536, 1565, 1970, 1961,
    1543, 1565, 1670, 1671, 1672, 1673, -- Zones Shadowlands supplémentaires
    -- Battle for Azeroth  
    875, 876, 862, 863, 864, 896, 942,
    1462, 1355, 1161, 1165, 1642, 1643, -- Zones BfA supplémentaires
    -- Legion + Argus (AJOUTÉ)
    630, 641, 650, 634, 680, 646, 790, 882,
    830, 882, 885, -- Mac'Aree, Antoran Wastes, Krokuun (Argus)
    -- Zones classiques qui peuvent avoir des expéditions
    1, 14, 15, 17, 37, 51, 61, -- Kalimdor
    13, 20, 23, 26, 27, 32, 36, -- Eastern Kingdoms  
    485, 486, 488, 490, 491, 492, -- Pandaria
    539, 540, 542, 543, 550, 552, 554 -- Draenor
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
    for _, mapID in ipairs(SCAN_ZONES) do
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
    for _, mapID in ipairs(SCAN_ZONES) do
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
        for _, mapID in ipairs(SCAN_ZONES) do
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
