-- ============================================================================
-- Gestionnaire des commandes slash et interface en ligne de commande
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée entre tous les fichiers
local addonName, addon = ...

-- Table pour stocker les commandes
addon.commands = {}

-- Fonction pour gérer les commandes slash
function addon:HandleSlashCommand(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "show" then
        self.UI:Show()
        
    elseif command == "hide" then
        self.UI:Hide()
        
    elseif command == "debug" or command == "diag" then
        if self.InventoryService then
            self.InventoryService:Diagnose()
        else
            self:Print("Service Inventaire non disponible")
        end
        
    elseif command == "expedition" or command == "exp" then
        if self.ExpeditionsService then
            local questID = tonumber(rest)
            local results = self.ExpeditionsService:Debug(questID)
            
            self:Print("=== DIAGNOSTIC EXPÉDITIONS ===")
            self:Print("Service activé : " .. (results.serviceEnabled and "OUI" or "NON"))
            self:Print("Expéditions surveillées : " .. results.monitoredCount)
            self:Print("Expéditions disponibles : " .. results.availableCount)
            self:Print("Zone actuelle : " .. (results.currentMapID or "Inconnue"))
            
            -- Afficher toutes les expéditions en cache
            local monitored = self.ExpeditionsService:GetMonitored()
            local available = self.ExpeditionsService:GetAvailable()
            
            self:Print("--- TOUTES LES EXPÉDITIONS SURVEILLÉES ---")
            for id, data in pairs(monitored) do
                local isAvailable = available[tonumber(id)] == true
                local status = isAvailable and "DISPONIBLE" or "NON DISPONIBLE"
                
                -- Test de carte pour chaque expédition
                local questInfo = C_TaskQuest.GetQuestInfoByQuestID(tonumber(id))
                local mapStatus = "PAS D'INFOS API"
                
                if questInfo then
                    mapStatus = questInfo.mapID and ("Zone API: " .. questInfo.mapID) or "PAS DE ZONE API"
                end
                
                -- Essayer de trouver dans les zones scannées
                local foundInZone = nil
                for _, mapID in ipairs({2248, 2339, 2214, 2215, 2255, 2256, 2346, 862, 634, 830, 882, 885}) do
                    local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
                    if quests then
                        for _, quest in ipairs(quests) do
                            if quest.questID == tonumber(id) then
                                foundInZone = mapID
                                break
                            end
                        end
                        if foundInZone then break end
                    end
                end
                
                if foundInZone then
                    mapStatus = "Zone trouvée: " .. foundInZone
                elseif questInfo and questInfo.mapID then
                    mapStatus = "Zone API: " .. questInfo.mapID
                end
                
                self:Print("ID " .. id .. " (" .. data.name .. ") : " .. status .. " | " .. mapStatus)
            end
            
            if questID then
                self:Print("--- ANALYSE EXPÉDITION " .. questID .. " ---")
                self:Print("Est World Quest : " .. (results.isWorldQuest and "OUI" or "NON"))
                self:Print("A des infos : " .. (results.questInfo and "OUI" or "NON"))
                self:Print("Est terminée : " .. (results.isCompleted and "OUI" or "NON"))
                self:Print("Détectée disponible : " .. (results.isAvailableByFunction and "OUI" or "NON"))
                self:Print("En cache : " .. (results.isInCache and "OUI" or "NON"))
                
                if results.foundInZones and #results.foundInZones > 0 then
                    self:Print("--- ZONES OÙ ELLE EST TROUVÉE ---")
                    for _, zoneInfo in ipairs(results.foundInZones) do
                        self:Print("Zone " .. zoneInfo.mapID .. " (" .. zoneInfo.mapName .. ")")
                        self:Print("  - World Quest: " .. (zoneInfo.isWorldQuest and "OUI" or "NON"))
                        self:Print("  - Terminée: " .. (zoneInfo.isCompleted and "OUI" or "NON"))
                        self:Print("  - Coordonnées: " .. (zoneInfo.hasCoordinates and "OUI" or "NON"))
                        self:Print("  - MapID de la quête: " .. (zoneInfo.questMapID or "N/A"))
                    end
                else
                    self:Print("Expédition introuvable dans les zones scannées")
                end
            end
        else
            self:Print("Service Expéditions non disponible")
        end
        
    elseif command == "expscan" then
        if self.ExpeditionsService then
            self.ExpeditionsService:ForceScan()
            self:Print("Scan forcé des expéditions effectué")
        else
            self:Print("Service Expéditions non disponible")
        end
        
    elseif command == "findzone" then
        -- Commande pour trouver dans quelle zone se trouve une expédition spécifique
        local questID = tonumber(rest)
        if not questID then
            self:Print("Usage: /utt findzone [ID]")
            return
        end
        
        self:Print("=== RECHERCHE DE ZONE POUR L'EXPÉDITION " .. questID .. " ===")
        
        -- Tester une liste étendue de zones d'Argus
        local argusZones = {830, 882, 885, 905, 994, 1669} -- Différents IDs possibles pour Argus
        
        -- Tester toutes les zones possibles
        local allTestZones = {
            -- Argus étendues
            830, 882, 885, 905, 994, 1669,
            -- TWW
            2248, 2339, 2214, 2215, 2255, 2256, 2346,
            -- Anciennes
            862, 634, 875, 876, 630, 641, 650
        }
        
        local found = false
        for _, mapID in ipairs(allTestZones) do
            local mapInfo = C_Map.GetMapInfo(mapID)
            local mapName = mapInfo and mapInfo.name or "Inconnue"
            local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
            
            if quests then
                for _, quest in ipairs(quests) do
                    if quest.questID == questID then
                        self:Print("TROUVÉE ! Zone " .. mapID .. " (" .. mapName .. ")")
                        self:Print("  - MapID de la quête: " .. (quest.mapID or "N/A"))
                        self:Print("  - Coordonnées: " .. (quest.x and quest.y and (quest.x .. ", " .. quest.y) or "N/A"))
                        found = true
                        break
                    end
                end
            end
        end
        
        if not found then
            self:Print("Expédition " .. questID .. " introuvable dans les zones testées")
            self:Print("Elle pourrait être dans une zone non couverte ou inactive")
        end
        
    elseif command == "expclear" then
        if self.ExpeditionsService then
            self.ExpeditionsService:ClearCache()
            self:Print("Cache des expéditions vidé et rescan effectué")
        else
            self:Print("Service Expéditions non disponible")
        end
        
    elseif command == "forceopen" then
        if self.InventoryService then
            local success, message = self.InventoryService:ForceOpenAll()
            self:Print(message)
        else
            self:Print("Service Inventaire non disponible")
        end
        
    elseif command == "reload" or command == "reset" then
        if self.InventoryService then
            self.InventoryService:Disable()
            C_Timer.After(0.5, function()
                self.InventoryService:Enable()
                self:Print("Service Inventaire redémarré")
            end)
        else
            self:Print("Service Inventaire non disponible")
        end
        
    elseif command == "updateicons" then
        if self.InventoryService then
            local count = self.InventoryService:UpdateMissingIcons()
            if count > 0 then
                self:Print(count .. " icône(s) mise(s) à jour")
            else
                self:Print("Aucune icône à mettre à jour")
            end
        else
            self:Print("Service Inventaire non disponible")
        end
        
    elseif command == "help" or command == "" then
        self:Print("Commandes disponibles :")
        self:Print("/utt show - Affiche l'interface")
        self:Print("/utt hide - Masque l'interface")
        self:Print("/utt debug - Diagnostic du service inventaire")
        self:Print("/utt expedition [ID] - Diagnostic des expéditions (optionnel: ID spécifique)")
        self:Print("/utt expscan - Force un scan des expéditions")
        self:Print("/utt findzone [ID] - Trouve la zone d'une expédition spécifique")
        self:Print("/utt expclear - Vide le cache et rescanne les expéditions")
        self:Print("/utt forceopen - Force l'ouverture des objets surveillés")
        self:Print("/utt reload - Redémarre le service inventaire")
        self:Print("/utt updateicons - Met à jour les icônes manquantes")
        self:Print("/utt help - Affiche cette aide")
        
    else
        self:Print("Commande inconnue. Tapez /utt help pour la liste des commandes.")
    end
end
