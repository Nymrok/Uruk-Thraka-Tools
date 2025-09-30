-- ============================================================================
-- Gestionnaire des commandes slash simplifiées
-- ============================================================================

local addonName, addon = ...

-- ============================================================================
-- FONCTION PRINCIPALE DE GESTION DES COMMANDES
-- ============================================================================

function addon:HandleSlashCommand(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "show" then
        -- Affiche la MainUI
        if self.UI then
            self.UI:Show()
            addon.Notifications:ModuleInfo("SlashCommands", "Interface principale affichée")
        else
            addon.Notifications:ModuleError("SlashCommands", "Interface principale non disponible")
        end
        
    elseif command == "hide" then
        -- Masque la MainUI
        if self.UI then
            self.UI:Hide()
            addon.Notifications:ModuleInfo("SlashCommands", "Interface principale masquée")
        else
            addon.Notifications:ModuleError("SlashCommands", "Interface principale non disponible")
        end
        
    elseif command == "scanzone" then
        -- Scan d'informations de zone
        local zoneID = tonumber(rest)
        
        -- Si aucun ID fourni, utiliser la zone actuelle du joueur
        if not zoneID then
            zoneID = C_Map.GetBestMapForUnit("player")
            if not zoneID then
                addon.Notifications:ModuleError("SlashCommands", "Impossible de déterminer la zone actuelle du joueur")
                addon.Notifications:ModulePrint("SlashCommands", "Usage: /utt scanzone [ID]")
                return
            end
            addon.Notifications:ModuleResult("SlashCommands", "=== SCAN ZONE ACTUELLE " .. zoneID .. " ===")
        else
            addon.Notifications:ModuleResult("SlashCommands", "=== SCAN ZONE " .. zoneID .. " ===")
        end
        
        local zoneInfo = C_Map.GetMapInfo(zoneID)
        if zoneInfo then
            addon.Notifications:ModulePrint("SlashCommands", "Nom: " .. (zoneInfo.name or "Inconnu"))
            addon.Notifications:ModulePrint("SlashCommands", "Type: " .. (zoneInfo.mapType or "Inconnu"))
            addon.Notifications:ModulePrint("SlashCommands", "ID Parent: " .. (zoneInfo.parentMapID or "Aucun"))
            addon.Notifications:ModulePrint("SlashCommands", "Niveau: " .. (zoneInfo.cosmicMapID or "Inconnu"))
        else
            addon.Notifications:ModuleNoResult("SlashCommands", "Aucune information trouvée pour la zone " .. zoneID)
        end
        
    elseif command == "scanitem" then
        -- Scan d'informations d'objet
        local itemID = tonumber(rest)
        if not itemID then
            addon.Notifications:ModulePrint("SlashCommands", "Usage: /utt scanitem [ID]")
            return
        end
        
        addon.Notifications:ModuleResult("SlashCommands", "=== SCAN ITEM " .. itemID .. " ===")
        
        -- Créer une référence d'item pour les APIs C_Item
        local item = itemID
        
        -- Vérifier si les données sont en cache
        local isCached = C_Item.IsItemDataCached(item)
        addon.Notifications:ModulePrint("SlashCommands", "Données en cache: " .. (isCached and "OUI" or "NON"))
        
        if isCached then
            -- GUID de l'objet
            local guid = C_Item.GetItemGUID(item)
            addon.Notifications:ModulePrint("SlashCommands", "GUID: " .. (guid or "Non disponible"))
            
            -- ID de l'objet
            local id = C_Item.GetItemID(item)
            addon.Notifications:ModulePrint("SlashCommands", "ID: " .. (id or "Non disponible"))
            
            -- Nom de l'objet
            local name = C_Item.GetItemName(item)
            addon.Notifications:ModulePrint("SlashCommands", "Nom: " .. (name or "Non disponible"))
            
            -- Qualité de l'objet
            local quality = C_Item.GetItemQuality(item)
            addon.Notifications:ModulePrint("SlashCommands", "Qualité: " .. (quality or "Non disponible"))
            
            -- Niveau de l'objet
            local level = C_Item.GetItemLevel(item)
            addon.Notifications:ModulePrint("SlashCommands", "Niveau: " .. (level or "Non disponible"))
            
            -- Statistiques de l'objet
            local stats = C_Item.GetItemStats(item)
            if stats then
                addon.Notifications:ModulePrint("SlashCommands", "Statistiques:")
                for stat, value in pairs(stats) do
                    addon.Notifications:ModulePrint("SlashCommands", "  " .. stat .. ": " .. value)
                end
            else
                addon.Notifications:ModulePrint("SlashCommands", "Statistiques: Non disponibles")
            end
            
            -- Type de l'objet
            local itemType, subType = C_Item.GetItemType(item)
            addon.Notifications:ModulePrint("SlashCommands", "Type: " .. (itemType or "Inconnu") .. " / " .. (subType or "Inconnu"))
            
            -- Objet lié
            local isBound = C_Item.IsBound(item)
            addon.Notifications:ModulePrint("SlashCommands", "Lié: " .. (isBound and "OUI" or "NON"))
            
            -- Objet corrompu
            local isCorrupted = C_Item.IsCorrupted(item)
            addon.Notifications:ModulePrint("SlashCommands", "Corrompu: " .. (isCorrupted and "OUI" or "NON"))
        else
            addon.Notifications:ModuleWarning("SlashCommands", "Données non disponibles en cache, certaines informations peuvent être manquantes")
        end
        
    elseif command == "scanexp" then
        -- Scan d'informations d'expédition/quête
        local questID = tonumber(rest)
        if not questID then
            addon.Notifications:ModulePrint("SlashCommands", "Usage: /utt scanexp [ID]")
            return
        end
        
        addon.Notifications:ModuleResult("SlashCommands", "=== SCAN EXPEDITION " .. questID .. " ===")
        
        -- World Quest
        local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
        addon.Notifications:ModulePrint("SlashCommands", "World Quest: " .. (isWorldQuest and "OUI" or "NON"))
        
        -- Titre de la quête
        local title = C_QuestLog.GetTitleForQuestID(questID)
        addon.Notifications:ModulePrint("SlashCommands", "Titre: " .. (title or "Non disponible"))
        
        -- Informations de tag
        local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
        if tagInfo then
            addon.Notifications:ModulePrint("SlashCommands", "Tag Type: " .. (tagInfo.tagName or "Inconnu"))
            addon.Notifications:ModulePrint("SlashCommands", "Tag ID: " .. (tagInfo.tagID or "Inconnu"))
        else
            addon.Notifications:ModulePrint("SlashCommands", "Tag: Non disponible")
        end
        
        -- Taille de groupe suggérée
        local groupSize = C_QuestLog.GetSuggestedGroupSize(questID)
        addon.Notifications:ModulePrint("SlashCommands", "Taille groupe suggérée: " .. (groupSize or "Non spécifiée"))
        
        -- Charger les données de quête
        local loadResult = C_QuestLog.RequestLoadQuestByID(questID)
        addon.Notifications:ModulePrint("SlashCommands", "Chargement demandé: " .. (loadResult and "SUCCÈS" or "ÉCHEC"))
        
        -- Note: GetQuestsOnMap et GetZoneStoryInfo nécessitent un mapID, pas questID
        addon.Notifications:ModuleInfo("SlashCommands", "Note: GetQuestsOnMap et GetZoneStoryInfo nécessitent un mapID")
        
    elseif command == "scanmob" then
        -- Scan d'informations de mob/unité
        local unitToken = rest
        if not unitToken or unitToken == "" then
            addon.Notifications:ModulePrint("SlashCommands", "Usage: /utt scanmob [TOKEN]")
            addon.Notifications:ModulePrint("SlashCommands", "Exemples: target, mouseover, player, party1, etc.")
            return
        end
        
        addon.Notifications:ModuleResult("SlashCommands", "=== SCAN MOB " .. unitToken .. " ===")
        
        -- Vérifier si l'unité existe
        if not UnitExists(unitToken) then
            addon.Notifications:ModuleError("SlashCommands", "Unité '" .. unitToken .. "' non trouvée")
            return
        end
        
        -- Informations de base
        local name = UnitName(unitToken)
        local level = UnitLevel(unitToken)
        local guid = UnitGUID(unitToken)
        
        addon.Notifications:ModulePrint("SlashCommands", "Nom: " .. (name or "Inconnu"))
        addon.Notifications:ModulePrint("SlashCommands", "Niveau: " .. (level or "Inconnu"))
        addon.Notifications:ModulePrint("SlashCommands", "GUID: " .. (guid or "Non disponible"))
        
        -- Informations tooltip via C_TooltipInfo
        local tooltipInfo = C_TooltipInfo.GetUnit(unitToken)
        if tooltipInfo then
            addon.Notifications:ModulePrint("SlashCommands", "Tooltip Info: Données disponibles")
            if tooltipInfo.lines then
                addon.Notifications:ModulePrint("SlashCommands", "Nombre de lignes tooltip: " .. #tooltipInfo.lines)
            end
        else
            addon.Notifications:ModulePrint("SlashCommands", "Tooltip Info: Non disponible")
        end
        
        -- Tooltip formaté
        local formattedTooltip = C_TooltipInfo.GetTooltipForUnit(unitToken)
        if formattedTooltip then
            addon.Notifications:ModulePrint("SlashCommands", "Tooltip formaté: Disponible")
        else
            addon.Notifications:ModulePrint("SlashCommands", "Tooltip formaté: Non disponible")
        end
        
    elseif command == "scantarget" then
        -- Scan de la cible actuelle du joueur
        local unitToken = "target"
        
        addon.Notifications:ModuleResult("SlashCommands", "=== SCAN CIBLE ===")
        
        -- Vérifier si l'unité existe
        if not UnitExists(unitToken) then
            addon.Notifications:ModuleError("SlashCommands", "Aucune cible sélectionnée")
            return
        end
        
        -- Informations de base
        local name = UnitName(unitToken)
        local level = UnitLevel(unitToken)
        local guid = UnitGUID(unitToken)
        
        addon.Notifications:ModulePrint("SlashCommands", "Nom: " .. (name or "Inconnu"))
        addon.Notifications:ModulePrint("SlashCommands", "Niveau: " .. (level or "Inconnu"))
        addon.Notifications:ModulePrint("SlashCommands", "GUID: " .. (guid or "Non disponible"))
        
        -- Informations tooltip via C_TooltipInfo
        local tooltipInfo = C_TooltipInfo.GetUnit(unitToken)
        if tooltipInfo then
            addon.Notifications:ModulePrint("SlashCommands", "Tooltip Info: Données disponibles")
            if tooltipInfo.lines then
                addon.Notifications:ModulePrint("SlashCommands", "Nombre de lignes tooltip: " .. #tooltipInfo.lines)
            end
        else
            addon.Notifications:ModulePrint("SlashCommands", "Tooltip Info: Non disponible")
        end
        
        -- Tooltip formaté
        local formattedTooltip = C_TooltipInfo.GetTooltipForUnit(unitToken)
        if formattedTooltip then
            addon.Notifications:ModulePrint("SlashCommands", "Tooltip formaté: Disponible")
        else
            addon.Notifications:ModulePrint("SlashCommands", "Tooltip formaté: Non disponible")
        end
        
    else
        -- Aide
        addon.Notifications:ModuleInfo("SlashCommands", "=== COMMANDES UTT ===")
        addon.Notifications:ModulePrint("SlashCommands", "/utt show - Affiche l'interface principale")
        addon.Notifications:ModulePrint("SlashCommands", "/utt hide - Masque l'interface principale")
        addon.Notifications:ModulePrint("SlashCommands", "/utt scanzone [ID] - Scan d'informations de zone (zone actuelle si aucun ID)")
        addon.Notifications:ModulePrint("SlashCommands", "/utt scanitem [ID] - Scan d'informations d'objet")
        addon.Notifications:ModulePrint("SlashCommands", "/utt scanexp [ID] - Scan d'informations d'expédition")
        addon.Notifications:ModulePrint("SlashCommands", "/utt scanmob [TOKEN] - Scan d'informations d'unité")
        addon.Notifications:ModulePrint("SlashCommands", "/utt scantarget - Scan de la cible actuelle")
    end
end