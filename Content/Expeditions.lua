-- ============================================================================
-- Interface utilisateur pour la gestion des expéditions
-- ============================================================================

local _, addon = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================
addon.Displayer = addon.Displayer or {}
addon.Displayer.Expeditions = {
    header = "Expéditions"
}

-- ============================================================================
-- VARIABLES LOCALES UI
-- ============================================================================
local displayFrame = nil
local itemsContainer = nil
local addInput = nil
local enabledCheckbox = nil
local expeditionsList = {} -- Liste sera transformée en ListComponent

-- ============================================================================
-- GESTION DE L'AFFICHAGE
-- ============================================================================

--[[
    Met à jour la liste des expéditions surveillées
]]
local function updateList()
    if not itemsContainer or not expeditionsList then return end
    
    local service = addon.ExpeditionsService
    if not service then
        addon.Notifications:Error("Service Expéditions non disponible")
        return
    end
    
    -- Callback de suppression d'une expédition
    local function onDeleteExpedition(questID, data)
        local removeResult = service:Remove(questID)
        if removeResult then
            addon.Notifications:ItemRemoved("Expédition", data.name or "Expédition", true)
            updateList() -- Rafraîchir la liste
        else
            addon.Notifications:ItemRemoved("Expédition", data.name or "Expédition", false)
        end
    end
    
    -- Mettre à jour la configuration du ListComponent avec le callback
    if expeditionsList then
        expeditionsList.config.onDelete = onDeleteExpedition
    end
    
    -- Utiliser le ListComponent standardisé
    local data = service:GetMonitored() or {}
    expeditionsList:Update(data, service:IsEnabled())
end

--[[
    Met à jour la visibilité des contrôles d'ajout
]]
local function updateAddSectionVisibility(isVisible)
    local elements = {addInput, displayFrame.addButton}
    for _, element in ipairs(elements) do
        if element then
            if isVisible then
                element:Show()
            else
                element:Hide()
            end
        end
    end
end

-- ============================================================================
-- ÉVÉNEMENTS UI
-- ============================================================================

--[[
    Gestionnaire pour l'ajout d'une expédition
]]
local function onAddExpedition()
    if not addInput then return end
    
    local questID = addInput:GetText()
    if not questID or questID == "" then
        print("|cFFFF0000[UTT]|r Veuillez entrer un ID d'expédition")
        return
    end
    
    local service = addon.ExpeditionsService
    if not service then
        print("|cFFFF0000[UTT]|r Service Expéditions non disponible")
        return
    end
    
    local success, message = service:Add(questID)
    
    if success then
        addInput:SetText("") -- Vider le champ
        print("|cFF00FF00[UTT]|r " .. message)
        
        -- Force une mise à jour immédiate de la liste pour afficher la couleur correcte
        C_Timer.After(0.1, function()
            updateList()
        end)
    else
        print("|cFFFF0000[UTT]|r Erreur : " .. message)
    end
end

--[[
    Gestionnaire pour l'activation/désactivation
]]
local function onToggleEnabled(enabled)
    local service = addon.ExpeditionsService
    if not service then return end
    
    if enabled then
        service:Enable()
    else
        service:Disable()
    end
    
    -- Mettre à jour la visibilité des contrôles
    updateAddSectionVisibility(enabled)
    
    -- Mettre à jour immédiatement la liste
    updateList()
end

-- ============================================================================
-- CRÉATION DU CONTENU
-- ============================================================================

--[[
    Crée le contenu de la page Expéditions
    @param frame Frame - Le conteneur d'affichage
]]
function addon.Displayer.Expeditions:CreateContent(frame)
    displayFrame = frame
    
    local service = addon.ExpeditionsService
    
    -- ========================================
    -- CHECKBOX D'ACTIVATION
    -- ========================================
    enabledCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    enabledCheckbox:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", 20, -20)
    enabledCheckbox:SetSize(24, 24)
    enabledCheckbox:SetChecked(service and service:IsEnabled() or false)
    enabledCheckbox:SetScript("OnClick", function(self)
        onToggleEnabled(self:GetChecked())
    end)
    
    local enabledLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enabledLabel:SetPoint("LEFT", enabledCheckbox, "RIGHT", 5, 0)
    enabledLabel:SetText("Surveillance des expéditions")
    enabledLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    
    -- ========================================
    -- ZONE D'AJOUT
    -- ========================================
    addInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    addInput:SetPoint("LEFT", enabledLabel, "RIGHT", 20, 0)
    addInput:SetSize(60, 25)
    addInput:SetAutoFocus(false)
    
    -- Filtre numérique
    addInput:SetScript("OnChar", function(self, char)
        if not char:match("%d") then
            return -- Bloquer les non-chiffres
        end
    end)
    
    addInput:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        local numbersOnly = text:gsub("%D", "") -- Supprimer tout sauf les chiffres
        if text ~= numbersOnly then
            self:SetText(numbersOnly)
        end
    end)
    
    addInput:SetScript("OnEnterPressed", onAddExpedition)
    
    local addButton = addon.ButtonTemplates.CreateAddButtonSD(frame, 28)
    addButton:SetPoint("LEFT", addInput, "RIGHT", 0, 0)
    addButton:SetScript("OnClick", onAddExpedition)
    frame.addButton = addButton
    
    -- ========================================
    -- CONTENEUR POUR LA LISTE
    -- ========================================
    itemsContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    itemsContainer:SetPoint("TOPLEFT", enabledCheckbox, "BOTTOMLEFT", 0, -10)
    itemsContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    itemsContainer:SetHeight(200)
    
    -- Initialiser le ListComponent
    expeditionsList = addon.ListComponent:Create(itemsContainer, {
        renderRow = addon.ListComponent.RenderExpedition
    })
    
    -- ========================================
    -- ÉVÉNEMENTS ET INITIALISATION
    -- ========================================
    
    -- Écouter les changements du service
    if service then
        service:OnChange(updateList)
        
        -- Vérifier que les callbacks existent avant de les utiliser
        if service.OnAvailable then
            service:OnAvailable(updateList)     -- Mise à jour quand expédition devient disponible
        end
        
        if service.OnUnavailable then
            service:OnUnavailable(updateList)   -- Mise à jour quand expédition devient indisponible
        end
    end
    
    -- Configuration initiale de la visibilité
    updateAddSectionVisibility(enabledCheckbox:GetChecked())
    
    -- Mise à jour initiale (après l'initialisation du ListComponent)
    updateList()
end

-- ============================================================================
-- API PUBLIQUE (compatibilité)
-- ============================================================================

--[[
    Met à jour la liste (pour compatibilité)
]]
function addon.Displayer.Expeditions:UpdateList()
    updateList()
end

--[[
    Récupère l'input ID (pour compatibilité avec l'ancien système)
]]
function addon.Displayer.Expeditions:GetIDInput()
    return addInput and addInput:GetText() or ""
end

--[[
    Actualise l'affichage (alias pour UpdateList)
]]
function addon.Displayer.Expeditions:RefreshList()
    updateList()
end