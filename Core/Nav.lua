-- ============================================================================
-- Système de navigation entre les différentes pages de l'interface
-- ============================================================================

local addonName, addon = ...
addon.Nav = {}

local buttons = {}
local currentSelectedPageId = nil

function addon.Nav:Init(navFrame)
    local yOffset = -20
    
    -- Fonction pour créer un bouton de navigation
    local function CreateNavButton(parent, text, pageId)
        local button = addon.ButtonTemplates.CreateHD_Btn_RedGrey(parent, text)
        button.pageId = pageId
        button.isSelected = false
        return button
    end

    -- Créer les boutons de navigation
    local pageOrder = {"Home", "Gear", "Inventory", "Quests", "Expeditions"}
    
    for _, pageId in ipairs(pageOrder) do
        local pageData = addon.Displayer[pageId]
        if pageData and pageData.header then
            local button = CreateNavButton(navFrame, pageData.header, pageId)
            button:SetPoint("TOP", navFrame, "TOP", 0, yOffset)
            button:SetHitRectInsets(6, 6, 5, 7)

            -- Script de clic pour changer de page
            button:SetScript("OnClick", function()
                self:SelectPage(pageId, false)
            end)
            
            -- Stocker le bouton
            buttons[pageId] = button
            yOffset = yOffset - 40
        end
    end
    
    -- Sélectionner la page par défaut
    self:SelectPage("Home", true)
end

--[[
    Récupère l'ID de la page actuellement sélectionnée
]]
function addon.Nav:GetCurrentPageId()
    return currentSelectedPageId
end

--[[
    Récupère la page actuellement sélectionnée
]]
function addon.Nav:GetCurrentPage()
    if currentSelectedPageId and addon.Displayer[currentSelectedPageId] then
        return addon.Displayer[currentSelectedPageId]
    end
    return nil
end

--[[
    Met à jour l'état visuel des boutons de navigation
]]
function addon.Nav:UpdateButtonStates(selectedPageId)
    for pageId, button in pairs(buttons) do
        if pageId == selectedPageId then
            -- Bouton sélectionné : GoldButtonHD
            if not button.isSelected then
                local parent = button:GetParent()
                local text = button:GetText()
                local point, relativeTo, relativePoint, xOfs, yOfs = button:GetPoint()
                
                button:Hide()
                button = nil
                
                local goldButton = addon.ButtonTemplates.CreateHD_Btn_RedGold(parent, text)
                goldButton:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
                goldButton:SetHitRectInsets(6, 6, 5, 7)
                goldButton.pageId = pageId
                goldButton.isSelected = true
                
                goldButton:SetScript("OnClick", function()
                    self:SelectPage(pageId, false)
                end)
                
                buttons[pageId] = goldButton
            end
        else
            -- Bouton non sélectionné : NormalButtonHD
            if button.isSelected then
                local parent = button:GetParent()
                local text = button:GetText()
                local point, relativeTo, relativePoint, xOfs, yOfs = button:GetPoint()
                
                button:Hide()
                button = nil
                
                local normalButton = addon.ButtonTemplates.CreateHD_Btn_RedGrey(parent, text)
                normalButton:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
                normalButton:SetHitRectInsets(6, 6, 5, 7)
                normalButton.pageId = pageId
                normalButton.isSelected = false
                
                normalButton:SetScript("OnClick", function()
                    self:SelectPage(pageId, false)
                end)
                
                buttons[pageId] = normalButton
            end
        end
    end
    
    currentSelectedPageId = selectedPageId
end

--[[
    Nettoie le contenu d'UTT_Display
]]
local function ClearDisplayContent()
    local displayFrame = _G["UTT_Display"]
    if not displayFrame then return end
    
    -- Nettoyage agressif des enfants (frames, boutons, etc.)
    local children = {displayFrame:GetChildren()}
    for _, child in pairs(children) do
        if child then
            child:Hide()
            child:ClearAllPoints()
            child:SetParent(nil)
        end
    end
    
    -- Nettoyage agressif des régions (textures, fontstrings, etc.)
    local regions = {displayFrame:GetRegions()}
    local backgroundTextureCount = 0
    
    for _, region in pairs(regions) do
        if region then
            local objectType = region:GetObjectType()
            
            if objectType == "Texture" then
                -- Compter les textures de fond (la première est le fond vert de MainUI)
                backgroundTextureCount = backgroundTextureCount + 1
                if backgroundTextureCount > 1 then
                    -- Supprimer toutes les textures sauf la première (fond vert pastel)
                    region:Hide()
                    region:ClearAllPoints()
                    region:SetParent(nil)
                end
            elseif objectType == "FontString" then
                -- Supprimer tous les FontStrings (textes des pages)
                region:Hide()
                region:ClearAllPoints()
                region:SetParent(nil)
            end
        end
    end
end

--[[
    Sélectionne et affiche une page
    @param pageId string - L'ID de la page à afficher
    @param isInitialLoad boolean - Si c'est le chargement initial
]]
function addon.Nav:SelectPage(pageId, isInitialLoad)    
    -- Mettre à jour l'état des boutons
    self:UpdateButtonStates(pageId)
    
    -- Nettoyer le contenu actuel
    ClearDisplayContent()
    
    -- Afficher le nouveau contenu
    local displayFrame = _G["UTT_Display"]
    if displayFrame and addon.Displayer[pageId] and addon.Displayer[pageId].CreateContent then
        addon.Displayer[pageId]:CreateContent(displayFrame)
    end
end

--[[
    Rafraîchit la page actuellement affichée
]]
function addon.Nav:RefreshCurrentPage()
    if currentSelectedPageId then
        self:SelectPage(currentSelectedPageId, false)
        return true
    end
    return false
end
