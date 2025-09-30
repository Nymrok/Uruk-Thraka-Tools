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
        addon.Notifications:ModuleError("Expéditions", "Service Expéditions non disponible")
        return
    end
    
    -- Configurer le callback de suppression
    expeditionsList:DeleteRow(function(questID, data)
        local removeResult = service:Remove(questID)
        if removeResult then
            addon.Notifications:ItemRemoved("Expédition", data.name or "Expédition", true)
            updateList() -- Rafraîchir la liste
        else
            addon.Notifications:ItemRemoved("Expédition", data.name or "Expédition", false)
        end
    end)
    
    -- Mettre à jour les données si le service est activé
    if service:IsEnabled() then
        local data = service:GetMonitored() or {}
        expeditionsList:SetData(data)
    else
        expeditionsList:SetData({}) -- Liste vide si désactivé
    end
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
        addon.Notifications:ModuleError("Expéditions", "Veuillez entrer une ID d'expédition")
        return
    end
    
    local service = addon.ExpeditionsService
    if not service then
        addon.Notifications:ModuleError("Expéditions", "Service Expéditions non disponible")
        return
    end
    
    local success, message = service:Add(questID)
    
    if success then
        addInput:SetText("") -- Vider le champ
        addon.Notifications:ModuleSuccess("Expéditions", message)
        
        -- Force une mise à jour immédiate de la liste pour afficher la couleur correcte
        C_Timer.After(0.1, function()
            updateList()
        end)
    else
        addon.Notifications:ModuleError("Expéditions", message)
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
    enabledLabel:SetText("Activer la surveillance des expéditions")
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
    expeditionsList = addon.ListComponent:Create(itemsContainer)
    
    -- Configurer le rendu des expéditions
    expeditionsList:CreateRow(function(rowFrame, questID, data)
        local viewButton = addon.ButtonTemplates.CreateHD_Btn_VisibilityOn(rowFrame)
        viewButton:SetPoint("LEFT", rowFrame, "LEFT", 3, 0)
        viewButton:SetSize(26, 26)
        
        local isAvailable = addon.ExpeditionsService and addon.ExpeditionsService:IsAvailable(questID)
        
        if isAvailable then
            viewButton:SetEnabled(true)
            viewButton:SetScript("OnClick", function()
                -- Trouver la zone où se trouve l'expédition
                local foundMapID = nil
                local service = addon.ExpeditionsService
                
                if service and service.SCAN_ZONES then
                    -- Chercher l'expédition dans les zones SCAN_ZONES du service
                    for _, mapID in ipairs(service.SCAN_ZONES) do
                        local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
                        if quests then
                            for _, quest in ipairs(quests) do
                                if quest.questID == questID then
                                    local isWorldQuest = C_QuestLog.IsWorldQuest(quest.questID)
                                    local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(quest.questID)
                                    
                                    if isWorldQuest and not isCompleted then
                                        foundMapID = mapID
                                        break
                                    end
                                end
                            end
                        end
                        if foundMapID then break end
                    end
                end
                
                -- Ouvrir la carte
                if foundMapID then
                    if not WorldMapFrame:IsShown() then
                        ToggleWorldMap()
                    end
                    WorldMapFrame:SetMapID(foundMapID)
                    local mapInfo = C_Map.GetMapInfo(foundMapID)
                    addon.Notifications:ModuleSuccess("Expéditions", "Carte ouverte : " .. (mapInfo and mapInfo.name or foundMapID) .. " pour " .. (data.name or questID))
                else
                    -- Si pas trouvé, ouvrir juste la carte
                    if not WorldMapFrame:IsShown() then
                        ToggleWorldMap()
                    end
                    addon.Notifications:ModuleWarning("Expéditions", "Expédition non trouvée sur la carte : " .. (data.name or questID))
                end
            end)
        else
            viewButton:SetEnabled(false)
        end
        
        -- Nom de l'expédition
        local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        nameText:SetPoint("LEFT", viewButton, "RIGHT", 5, 0)
        nameText:SetText(data.name or "Expédition inconnue")
        
        if isAvailable then
            nameText:SetTextColor(0, 1, 0, 1) -- Vert si disponible
        else
            nameText:SetTextColor(0.3, 0.3, 0.3, 1) -- Rouge si indisponible
        end
        
        -- ID de l'expédition
        local idText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        idText:SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
        idText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
        idText:SetText("ID : " .. questID)
        idText:SetTextColor(0.5, 0.5, 0.5, 0.8)
    end)
    
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