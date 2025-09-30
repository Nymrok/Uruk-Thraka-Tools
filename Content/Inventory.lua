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
    itemsList = addon.ListComponent:Create(itemsContainer)
    
    -- Configurer le callback de suppression
    itemsList:DeleteRow(function(itemID, itemData)
        if addon.InventoryService then
            addon.InventoryService:Remove(itemID)
            updateItemsList() -- Mettre à jour immédiatement la liste
        end
    end)
    
    -- Configurer le rendu des objets d'inventaire
    itemsList:CreateRow(function(rowFrame, itemID, data)
        -- Icône de l'objet
        local icon = rowFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", rowFrame, "LEFT", 6, 0)
        icon:SetSize(22, 22)
        
        local iconTexture = data.icon
        if not iconTexture or iconTexture == 134400 then
            local _, _, _, _, _, _, _, _, _, realTimeIcon = GetItemInfo(itemID)
            iconTexture = realTimeIcon or 134400
        end
        
        icon:SetTexture(iconTexture)
        
        -- Bordure de l'icône
        local iconBorder = rowFrame:CreateTexture(nil, "OVERLAY")
        iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
        iconBorder:SetSize(40, 40)
        iconBorder:SetAtlas("GarrMission_WeakEncounterAbilityBorder-Lg")
        iconBorder:SetVertexColor(0.3, 0.3, 0.3, 1)
        
        -- Nom de l'objet
        local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        nameText:SetText(data.name or "Inconnu")
        nameText:SetTextColor(1, 1, 1, 1)
        
        -- ID de l'objet
        local idText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        idText:SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
        idText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
        idText:SetText("ID : " .. itemID)
        idText:SetTextColor(0.5, 0.5, 0.5, 0.8)
    end)
    
    -- Fonction pour mettre à jour la liste
    function updateItemsList()
        if AutoOpen_Checkbox:GetChecked() and addon.InventoryService then
            local monitoredItems = addon.InventoryService:GetMonitored() or {}
            itemsList:SetData(monitoredItems)
        else
            itemsList:SetData({}) -- Liste vide si désactivé
        end
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
