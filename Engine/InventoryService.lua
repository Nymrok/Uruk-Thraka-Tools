-- ============================================================================
-- Service centralisé pour la gestion automatique de l'inventaire
-- ============================================================================

local addonName, addon = ...

addon.InventoryService = addon.InventoryService or {}

-- ============================================================================
-- ÉTAT PRIVÉ
-- ============================================================================
local isEnabled = false
local monitoredCache = {}
local originalBagWatcher = nil
local bagOpenHooksInstalled = false
local bagStates = {}
local stats = {
    itemsOpened = 0,
    totalValue = 0,
    sessionsCount = 0,
    lastReset = time()
}

-- Callbacks
local callbacks = {
    onItemOpened = {},
    onItemAdded = {},
    onItemRemoved = {},
    onChange = {}
}

-- Items par défaut suggérés (conteneurs courants de WoW)
local DEFAULT_ITEMS = {
    [184869] = "Sac de pièces de la Garde",
    [174652] = "Coffre de guerre",
    [171209] = "Sac de fournitures de la Vengeance", 
    [178128] = "Coffre de l'Assemblage",
    [187543] = "Coffre de butin mystique",
    [191139] = "Coffre de fournitures draconiques",
    [202079] = "Coffre de l'expédition",
    [191251] = "Coffre d'Iskaara",
    [198863] = "Coffre des centaures Maruukai"
}

-- ============================================================================
-- UTILITAIRES PRIVÉS
-- ============================================================================

--[[
    S'assure que les données de sauvegarde existent
]]
local function ensureData()
    addon:EnsureUTTData()
    UTT_Data.AutoOpenItems = UTT_Data.AutoOpenItems or {}
    UTT_Data.autoOpenEnabled = UTT_Data.autoOpenEnabled ~= nil and UTT_Data.autoOpenEnabled or false
    UTT_Data.inventoryStats = UTT_Data.inventoryStats or {
        itemsOpened = 0,
        totalValue = 0,
        sessionsCount = 0,
        lastReset = time()
    }
end

--[[
    Récupère le nom d'un item à partir de son ID
]]
local function getItemName(itemID)
    local name = GetItemInfo(itemID)
    return name and name ~= "" and name or ("Item " .. itemID)
end

--[[
    Récupère la valeur de vente d'un item
]]
local function getItemValue(itemID)
    local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemID)
    return sellPrice or 0
end

--[[
    Met à jour les statistiques d'ouverture
]]
local function updateStats(itemID, count)
    count = count or 1
    stats.itemsOpened = stats.itemsOpened + count
    stats.totalValue = stats.totalValue + (getItemValue(itemID) * count)
    
    -- Sauvegarder les statistiques
    ensureData()
    UTT_Data.inventoryStats = stats
end

--[[
    Vérifie si un item doit être ouvert automatiquement
]]
local function shouldOpenItem(itemID)
    if not isEnabled then return false end
    ensureData()
    return UTT_Data.AutoOpenItems[itemID] ~= nil
end

--[[
    Traite l'ouverture automatique lors de la mise à jour d'un sac
]]
local function onBagUpdate(bagID)
    if not isEnabled then return end
    
    -- Debug pour vérifier l'activation
    --print("|cFF33AA33[UTT Debug]|r BAG_UPDATE déclenché pour sac " .. (bagID or "nil"))
    
    -- Parcourir les slots du sac mis à jour
    local numSlots = C_Container.GetContainerNumSlots(bagID)
    for slotID = 1, numSlots do
        local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
        
        if itemInfo and itemInfo.itemID then
            local itemID = itemInfo.itemID
            local stackCount = itemInfo.stackCount or 1
            
            if shouldOpenItem(itemID) then
                -- Délai plus court et validation plus robuste
                C_Timer.After(0.05, function()
                    -- Revérifier que l'item est toujours présent
                    local currentItemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
                    if currentItemInfo and currentItemInfo.itemID == itemID then
                        C_Container.UseContainerItem(bagID, slotID)
                        
                        -- Mettre à jour les statistiques
                        updateStats(itemID, stackCount)
                        
                        -- Message de confirmation (optionnel pour debug)
                        print("|cFF00FF00[UTT]|r Ouverture automatique : " .. getItemName(itemID))
                        
                        -- Notifier les callbacks
                        for _, callback in ipairs(callbacks.onItemOpened) do
                            pcall(callback, itemID, getItemName(itemID), stackCount)
                        end
                    end
                end)
            end
        end
    end
end

--[[
    Traite l'ouverture automatique lors de l'ouverture des sacs
]]
local function processAutoOpenOnBagOpen()
    if not isEnabled then return end
    
    ensureData()
    if not UTT_Data.AutoOpenItems or next(UTT_Data.AutoOpenItems) == nil then
        return
    end
    
    -- Scanner tous les sacs (0-4) et ouvrir les objets surveillés
    for bagID = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bagID)
        for slotID = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
            
            if itemInfo and itemInfo.itemID then
                local itemID = itemInfo.itemID
                local stackCount = itemInfo.stackCount or 1
                
                if shouldOpenItem(itemID) then
                    -- Délai légèrement plus long pour l'ouverture manuelle de sacs
                    C_Timer.After(0.2, function()
                        -- Revérifier que l'item est toujours présent
                        local currentItemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
                        if currentItemInfo and currentItemInfo.itemID == itemID then
                            C_Container.UseContainerItem(bagID, slotID)
                            
                            -- Mettre à jour les statistiques
                            updateStats(itemID, stackCount)
                            
                            -- Message de confirmation
                            print("|cFF00FF00[UTT]|r Ouverture automatique : " .. getItemName(itemID))
                            
                            -- Notifier les callbacks
                            for _, callback in ipairs(callbacks.onItemOpened) do
                                pcall(callback, itemID, getItemName(itemID), stackCount)
                            end
                        end
                    end)
                end
            end
        end
    end
end

--[[
    Installe le système de surveillance des sacs
]]
local function installBagWatcher()
    if originalBagWatcher then return end -- Déjà installé
    
    -- Créer le frame d'événements
    local eventFrame = CreateFrame("Frame", "UTT_InventoryWatcher")
    
    -- Enregistrer plusieurs événements pour une meilleure détection
    eventFrame:RegisterEvent("BAG_UPDATE")
    eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    eventFrame:RegisterEvent("ITEM_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, bagID)
        if event == "BAG_UPDATE" and bagID and bagID >= 0 and bagID <= 4 then
            onBagUpdate(bagID)
        elseif event == "BAG_UPDATE_DELAYED" then
            -- Scanner tous les sacs pour les items manqués
            for bag = 0, 4 do
                onBagUpdate(bag)
            end
        elseif event == "ITEM_CHANGED" then
            -- Scanner tous les sacs en cas de changement d'item
            for bag = 0, 4 do
                onBagUpdate(bag)
            end
        end
    end)
    
    originalBagWatcher = eventFrame
end

--[[
    Installe les hooks pour détecter l'ouverture manuelle des sacs
]]
local function installBagOpenHooks()
    if bagOpenHooksInstalled then return end -- Déjà installé
    
    -- Initialiser l'état des sacs (0-4 pour les sacs principaux)
    for bagID = 0, 4 do
        bagStates[bagID] = IsBagOpen and IsBagOpen(bagID) or false
    end
    
    -- Hook pour l'affichage des frames de sacs (Retail)
    if ContainerFrame_OnShow then
        hooksecurefunc("ContainerFrame_OnShow", function(frame)
            if isEnabled and frame then
                local bagID = frame.GetID and frame:GetID()
                if bagID and bagID >= 0 and bagID <= 4 and not bagStates[bagID] then
                    bagStates[bagID] = true
                    -- Délai pour laisser le temps au sac de s'ouvrir complètement
                    C_Timer.After(0.1, processAutoOpenOnBagOpen)
                end
            end
        end)
        
        hooksecurefunc("ContainerFrame_OnHide", function(frame)
            if frame then
                local bagID = frame.GetID and frame:GetID()
                if bagID and bagID >= 0 and bagID <= 4 and bagStates[bagID] then
                    bagStates[bagID] = false
                end
            end
        end)
    end
    
    -- Hook pour la fonction ToggleBag
    if ToggleBag then
        hooksecurefunc("ToggleBag", function(bagID)
            if isEnabled and bagID >= 0 and bagID <= 4 then
                C_Timer.After(0.1, function()
                    local isOpen = IsBagOpen and IsBagOpen(bagID) or false
                    if isOpen and not bagStates[bagID] then
                        bagStates[bagID] = true
                        processAutoOpenOnBagOpen()
                    elseif not isOpen and bagStates[bagID] then
                        bagStates[bagID] = false
                    end
                end)
            end
        end)
    end
    
    -- Hook pour ToggleAllBags (ouvrir tous les sacs)
    if ToggleAllBags then
        hooksecurefunc("ToggleAllBags", function()
            if isEnabled then
                C_Timer.After(0.2, processAutoOpenOnBagOpen)
            end
        end)
    end
    
    bagOpenHooksInstalled = true
end

--[[
    Désinstalle le système de surveillance des sacs
]]
local function uninstallBagWatcher()
    if originalBagWatcher then
        originalBagWatcher:UnregisterAllEvents()
        originalBagWatcher:SetScript("OnEvent", nil)
        originalBagWatcher = nil
    end
end

-- ============================================================================
-- API PUBLIQUE
-- ============================================================================

--[[
    Vérifie si le service est activé
    @return boolean - true si activé
]]
function addon.InventoryService:IsEnabled()
    return isEnabled
end

--[[
    Active le service d'ouverture automatique
]]
function addon.InventoryService:Enable()
    ensureData()
    isEnabled = true
    UTT_Data.autoOpenEnabled = true
    installBagWatcher()
    installBagOpenHooks()  -- Ajouter la détection d'ouverture de sacs
    
    -- Incrémenter le compteur de sessions
    stats.sessionsCount = stats.sessionsCount + 1
    UTT_Data.inventoryStats = stats
    
    -- Notifier les changements
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
end

--[[
    Désactive le service d'ouverture automatique
]]
function addon.InventoryService:Disable()
    ensureData()
    isEnabled = false
    UTT_Data.autoOpenEnabled = false
    uninstallBagWatcher()
    
    -- Notifier les changements
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
end

-- ============================================================================
-- API PUBLIQUE STANDARDISÉE
-- ============================================================================

--[[
    Ajoute un item à surveiller (API standardisée)
    @param itemID number|string - L'ID de l'item
    @return boolean, string - Succès et message
]]
function addon.InventoryService:Add(itemID)
    return self:AddItem(itemID)
end

--[[
    Supprime un item de la surveillance (API standardisée)
    @param itemID number|string - L'ID de l'item
    @return boolean, string - Succès et message
]]
function addon.InventoryService:Remove(itemID)
    return self:RemoveItem(itemID)
end

--[[
    Récupère les items surveillés (API standardisée)
    @return table - Table des items surveillés
]]
function addon.InventoryService:GetMonitored()
    return self:GetMonitoredItems()
end

-- ============================================================================
-- API PUBLIQUE DÉTAILLÉE
-- ============================================================================

--[[
    Ajoute un item à ouvrir automatiquement
    @param itemID number|string - L'ID de l'item
    @return boolean, string - Succès et message
]]
function addon.InventoryService:AddItem(itemID)
    if not itemID or not tonumber(itemID) then
        return false, "ID invalide"
    end
    
    itemID = tonumber(itemID)
    
    -- Vérifier que l'item existe (avec retry pour les items non cached)
    local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if not itemName then
        -- Essayer de charger l'info de l'item
        local item = Item:CreateFromItemID(itemID)
        if item:IsItemEmpty() then
            return false, "Cet ID ne correspond pas à un item valide"
        end
        item:ContinueOnItemLoad(function()
            local loadedName, _, _, _, _, _, _, _, _, loadedTexture = GetItemInfo(itemID)
            itemName = loadedName or ("Item " .. itemID)
            itemTexture = loadedTexture or addon.Textures.DEFAULT_ICON
        end)
        itemName = "Item " .. itemID -- Fallback temporaire
        itemTexture = addon.Textures.DEFAULT_ICON -- Fallback temporaire
    end
    
    ensureData()
    
    if UTT_Data.AutoOpenItems[itemID] then
        return false, "Item déjà surveillé"
    end
    
    UTT_Data.AutoOpenItems[itemID] = {
        id = itemID,
        name = itemName,
        icon = itemTexture or addon.Textures.DEFAULT_ICON,
        addedAt = time()
    }
    
    -- Notifier les callbacks
    for _, callback in ipairs(callbacks.onItemAdded) do
        pcall(callback, itemID, itemName)
    end
    
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
    
    return true, "Item ajouté : " .. itemName
end

--[[
    Supprime un item de l'ouverture automatique
    @param itemID number - L'ID de l'item
    @return boolean, string - Succès et message
]]
function addon.InventoryService:RemoveItem(itemID)
    if not itemID then 
        return false, "ID manquant"
    end
    
    ensureData()
    itemID = tonumber(itemID)
    local data = UTT_Data.AutoOpenItems[itemID]
    
    if not data then 
        return false, "Item non surveillé"
    end
    
    UTT_Data.AutoOpenItems[itemID] = nil
    
    -- Notifier les callbacks
    for _, callback in ipairs(callbacks.onItemRemoved) do
        pcall(callback, itemID, data.name)
    end
    
    for _, callback in ipairs(callbacks.onChange) do
        pcall(callback)
    end
    
    return true, "Item supprimé : " .. data.name
end

--[[
    Récupère tous les items surveillés
    @return table - Table des items surveillés
]]
function addon.InventoryService:GetMonitoredItems()
    ensureData()
    return UTT_Data.AutoOpenItems or {}
end

--[[
    Récupère les statistiques d'ouverture
    @return table - Table des statistiques
]]
function addon.InventoryService:GetStats()
    ensureData()
    -- Fusionner les stats en mémoire avec celles sauvegardées
    local savedStats = UTT_Data.inventoryStats or {}
    return {
        itemsOpened = savedStats.itemsOpened or stats.itemsOpened,
        totalValue = savedStats.totalValue or stats.totalValue,
        sessionsCount = savedStats.sessionsCount or stats.sessionsCount,
        lastReset = savedStats.lastReset or stats.lastReset
    }
end

--[[
    Remet à zéro les statistiques
    @return boolean, string - Succès et message
]]
function addon.InventoryService:ResetStats()
    stats = {
        itemsOpened = 0,
        totalValue = 0,
        sessionsCount = 0,
        lastReset = time()
    }
    
    ensureData()
    UTT_Data.inventoryStats = stats
    
    return true, "Statistiques remises à zéro"
end

--[[
    Récupère la liste des items par défaut suggérés
    @return table - Table des items par défaut
]]
function addon.InventoryService:GetDefaultItems()
    return DEFAULT_ITEMS
end

--[[
    Ajoute tous les items par défaut
    @return boolean, string - Succès et message avec nombre d'items ajoutés
]]
function addon.InventoryService:AddDefaultItems()
    local added = 0
    local failed = 0
    
    for itemID, name in pairs(DEFAULT_ITEMS) do
        local success = self:AddItem(itemID)
        if success then
            added = added + 1
        else
            failed = failed + 1
        end
    end
    
    local message = ""
    if added > 0 then
        message = added .. " item(s) par défaut ajouté(s)"
    end
    if failed > 0 then
        if message ~= "" then message = message .. ", " end
        message = message .. failed .. " déjà présent(s)"
    end
    
    return added > 0, message
end

--[[
    Force l'ouverture de tous les items surveillés présents dans les sacs
]]
function addon.InventoryService:ForceOpenAll()
    if not isEnabled then
        return false, "Service désactivé"
    end
    
    local opened = 0
    
    -- Parcourir tous les sacs
    for bagID = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bagID)
        for slotID = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
            
            if itemInfo and itemInfo.itemID and shouldOpenItem(itemInfo.itemID) then
                C_Container.UseContainerItem(bagID, slotID)
                opened = opened + (itemInfo.stackCount or 1)
            end
        end
    end
    
    return opened > 0, opened .. " item(s) ouvert(s)"
end

--[[
    Met à jour les icônes manquantes pour tous les items surveillés
    @return number - Nombre d'icônes mises à jour
]]
function addon.InventoryService:UpdateMissingIcons()
    ensureData()
    local updated = 0
    
    for itemID, itemData in pairs(UTT_Data.AutoOpenItems) do
        if not itemData.icon or itemData.icon == addon.Textures.DEFAULT_ICON then
            local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
            if itemTexture then
                itemData.icon = itemTexture
                updated = updated + 1
            end
        end
    end
    
    if updated > 0 then
        -- Notifier les callbacks de changement
        for _, callback in ipairs(callbacks.onChange) do
            pcall(callback)
        end
        
        print("|cFF33AA33[UTT]|r " .. updated .. " icône(s) mise(s) à jour")
    end
    
    return updated
end

--[[
    Diagnostique l'état du service d'ouverture automatique
    @return string - Rapport de diagnostic
]]
function addon.InventoryService:Diagnose()
    local report = {}
    
    table.insert(report, "=== DIAGNOSTIC SERVICE INVENTAIRE ===")
    table.insert(report, "État du service : " .. (isEnabled and "ACTIVÉ" or "DÉSACTIVÉ"))
    
    ensureData()
    local monitoredCount = 0
    for _ in pairs(UTT_Data.AutoOpenItems or {}) do
        monitoredCount = monitoredCount + 1
    end
    table.insert(report, "Objets surveillés : " .. monitoredCount)
    
    table.insert(report, "Watcher installé : " .. (originalBagWatcher and "OUI" or "NON"))
    
    -- Vérifier les objets présents dans les sacs
    local foundItems = {}
    for bagID = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bagID)
        for slotID = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
            if itemInfo and itemInfo.itemID and shouldOpenItem(itemInfo.itemID) then
                local itemName = getItemName(itemInfo.itemID)
                table.insert(foundItems, itemName .. " (x" .. (itemInfo.stackCount or 1) .. ")")
            end
        end
    end
    
    if #foundItems > 0 then
        table.insert(report, "Objets trouvés dans les sacs :")
        for _, item in ipairs(foundItems) do
            table.insert(report, "  • " .. item)
        end
    else
        table.insert(report, "Aucun objet surveillé trouvé dans les sacs")
    end
    
    table.insert(report, "==========================")
    
    local fullReport = table.concat(report, "\n")
    print(fullReport)
    return fullReport
end

-- ============================================================================
-- SYSTÈME D'ÉVÉNEMENTS
-- ============================================================================

--[[
    Enregistre un callback pour les items ouverts
    @param callback function - Fonction appelée avec (itemID, itemName, count)
]]
function addon.InventoryService:OnItemOpened(callback)
    if type(callback) == "function" then
        table.insert(callbacks.onItemOpened, callback)
    end
end

--[[
    Enregistre un callback pour les items ajoutés à la surveillance
    @param callback function - Fonction appelée avec (itemID, itemName)
]]
function addon.InventoryService:OnItemAdded(callback)
    if type(callback) == "function" then
        table.insert(callbacks.onItemAdded, callback)
    end
end

--[[
    Enregistre un callback pour les items supprimés de la surveillance
    @param callback function - Fonction appelée avec (itemID, itemName)
]]
function addon.InventoryService:OnItemRemoved(callback)
    if type(callback) == "function" then
        table.insert(callbacks.onItemRemoved, callback)
    end
end

--[[
    Enregistre un callback pour tous changements de la liste
    @param callback function - Fonction appelée sans paramètres
]]
function addon.InventoryService:OnChange(callback)
    if type(callback) == "function" then
        table.insert(callbacks.onChange, callback)
    end
end

--[[
    Enregistre un callback pour un événement donné
    @param eventName string - Nom de l'événement (onChange, onItemOpened, onItemAdded, onItemRemoved)
    @param callback function - Fonction à appeler
    @return boolean - Succès de l'enregistrement
]]
function addon.InventoryService:RegisterCallback(eventName, callback)
    if not callbacks[eventName] then
        return false
    end
    
    if type(callback) ~= "function" then
        return false
    end
    
    table.insert(callbacks[eventName], callback)
    return true
end

--[[
    Supprime un callback pour un événement donné
    @param eventName string - Nom de l'événement
    @param callback function - Fonction à supprimer
    @return boolean - Succès de la suppression
]]
function addon.InventoryService:UnregisterCallback(eventName, callback)
    if not callbacks[eventName] then
        return false
    end
    
    for i, cb in ipairs(callbacks[eventName]) do
        if cb == callback then
            table.remove(callbacks[eventName], i)
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- INITIALISATION
-- ============================================================================

--[[
    Initialise le service d'inventaire
]]
function addon.InventoryService:Init()
    ensureData()
    isEnabled = UTT_Data.autoOpenEnabled or false
    stats = UTT_Data.inventoryStats or stats
    
    if isEnabled then
        installBagWatcher()
        installBagOpenHooks()  -- Installer aussi les hooks d'ouverture de sacs
    end
end
