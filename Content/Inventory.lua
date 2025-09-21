-- ============================================================================
-- Interface utilisateur pour la gestion de l'inventaire et du butin
-- ============================================================================
local addonName, addon = ...
addon.Displayer = addon.Displayer or {}
addon.Displayer.Inventory = {}
addon.Displayer.Inventory.header = "Inventaire"

function addon.Displayer.Inventory:CreateContent(displayFrame)    
    -- Variables locales pour l'UI
    local itemsContainer
    local itemsList
    
    local FastLoot_Checkbox = CreateFrame("CheckButton", nil, displayFrame, "UICheckButtonTemplate")
    FastLoot_Checkbox:SetSize(24, 24)
    FastLoot_Checkbox:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", 20, -20)
    FastLoot_Checkbox:SetChecked(addon.FastLoot and addon.FastLoot:IsEnabled() or false)

    local FastLoot_Description = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    FastLoot_Description:SetPoint("LEFT", FastLoot_Checkbox, "RIGHT", 5, 0)
    FastLoot_Description:SetText("Ramassage rapide du butin")
    FastLoot_Description:SetTextColor(1, 1, 1, 1)

    FastLoot_Checkbox:SetScript("OnClick", function(self)
        if not addon.FastLoot then return end
        if self:GetChecked() then
            addon.FastLoot:Enable()
        else
            addon.FastLoot:Disable()
        end
    end)

    local AutoSellGrey_Checkbox = CreateFrame("CheckButton", nil, displayFrame, "UICheckButtonTemplate")
    AutoSellGrey_Checkbox:SetSize(24, 24)
    AutoSellGrey_Checkbox:SetPoint("TOPLEFT", FastLoot_Checkbox, "BOTTOMLEFT", 0, -6)
    AutoSellGrey_Checkbox:SetChecked(addon.AutoSellGrey and addon.AutoSellGrey:IsEnabled() or false)
    
    local AutoSellGrey_Description = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    AutoSellGrey_Description:SetPoint("LEFT", AutoSellGrey_Checkbox, "RIGHT", 5, 0)
    AutoSellGrey_Description:SetText("Vendre automatiquement les objets gris")
    AutoSellGrey_Description:SetTextColor(1, 1, 1, 1)
    
    AutoSellGrey_Checkbox:SetScript("OnClick", function(self)
        if not addon.AutoSellGrey then return end
        if self:GetChecked() then
            addon.AutoSellGrey:Enable()
        else
            addon.AutoSellGrey:Disable()
        end
    end)

    local AutoOpen_Checkbox = CreateFrame("CheckButton", nil, displayFrame, "UICheckButtonTemplate")
    AutoOpen_Checkbox:SetSize(24, 24)
    AutoOpen_Checkbox:SetPoint("TOPLEFT", AutoSellGrey_Checkbox, "BOTTOMLEFT", 0, -6)
    AutoOpen_Checkbox:SetChecked(addon.InventoryService and addon.InventoryService:IsEnabled() or false)
    
    local AutoOpen_Description = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    AutoOpen_Description:SetPoint("LEFT", AutoOpen_Checkbox, "RIGHT", 5, 0)
    AutoOpen_Description:SetText("Ouverture automatique des conteneurs")
    AutoOpen_Description:SetTextColor(1, 1, 1, 1)

    -- ========================================
    -- CONTENEUR POUR LA LISTE
    -- ========================================
    itemsContainer = CreateFrame("Frame", nil, displayFrame, "BackdropTemplate")
    itemsContainer:SetPoint("TOPLEFT", AutoOpen_Checkbox, "BOTTOMLEFT", 0, -10)
    itemsContainer:SetPoint("BOTTOMRIGHT", displayFrame, "BOTTOMRIGHT", -10, 10)
    
    -- Initialiser le ListComponent
    itemsList = addon.ListComponent:Create(itemsContainer, {
        emptyMessage = "Aucun objet configuré pour l'ouverture automatique",
        renderRow = addon.ListComponent.RenderInventoryItem,
        onDelete = function(itemID, itemData)
            if addon.InventoryService then
                addon.InventoryService:Remove(itemID)
                updateItemsList() -- Mettre à jour immédiatement la liste
            end
        end
    })
    
    -- Fonction pour mettre à jour la liste
    function updateItemsList()
        local monitoredItems = {}
        if addon.InventoryService then
            monitoredItems = addon.InventoryService:GetMonitored()
        end
        
        local isEnabled = AutoOpen_Checkbox:GetChecked()
        itemsList:Update(monitoredItems, isEnabled)
    end
    
    -- Mettre à jour la liste au démarrage
    updateItemsList()
    
    -- ========================================
    -- ÉVÉNEMENTS ET INITIALISATION
    -- ========================================
    
    -- Écouter les changements du service
    if addon.InventoryService then
        -- Callback de mise à jour de la liste
        if addon.InventoryService.OnChange then
            addon.InventoryService:OnChange(updateItemsList)
        end
        
        -- Callbacks pour les ajouts/suppressions
        if addon.InventoryService.OnItemAdded then
            addon.InventoryService:OnItemAdded(updateItemsList)
        end
        
        if addon.InventoryService.OnItemRemoved then
            addon.InventoryService:OnItemRemoved(updateItemsList)
        end
    end
    
    -- Fonction pour gérer l'état visuel
    local function updateVisualState()
        local isEnabled = AutoOpen_Checkbox:GetChecked()
        
        -- Description reste toujours normale
        AutoOpen_Description:SetTextColor(1, 1, 1, 1)
        
        -- Mettre à jour la liste
        updateItemsList()
    end
    
    -- Gestion du drag & drop sur toute la displayFrame
    displayFrame:SetScript("OnReceiveDrag", function(self)
        -- Vérifier si le service est activé
        if not AutoOpen_Checkbox:GetChecked() then
            return
        end
        
        local cursorType, itemID = GetCursorInfo()
        if cursorType == "item" and itemID then
            if addon.InventoryService then
                addon.InventoryService:Add(itemID)
            end
            ClearCursor()
        end
    end)
    
    -- Alternative : utiliser OnMouseUp pour capturer les drops d'items
    displayFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            local cursorType, itemID = GetCursorInfo()
            if cursorType == "item" and itemID and AutoOpen_Checkbox:GetChecked() then
                if addon.InventoryService then
                    addon.InventoryService:Add(itemID)
                end
                ClearCursor()
            end
        end
    end)
    
    AutoOpen_Checkbox:SetScript("OnClick", function(self)
        if not addon.InventoryService then return end
        if self:GetChecked() then
            addon.InventoryService:Enable()
        else
            addon.InventoryService:Disable()
        end
        -- Mettre à jour l'état visuel
        updateVisualState()
    end)
    
    -- Enregistrer les callbacks du service
    if addon.InventoryService then
        addon.InventoryService:RegisterCallback("onChange", function()
            updateItemsList()
        end)
    end
    
    -- Initialiser l'état visuel au démarrage
    updateVisualState()
end
