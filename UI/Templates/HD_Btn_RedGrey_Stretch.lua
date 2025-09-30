-- ============================================================================
-- Template de bouton HD_Btn_RedGrey_Stretch
-- ============================================================================

local addonName, addon = ...

-- Namespace pour les templates de boutons
addon.ButtonTemplates = addon.ButtonTemplates or {}

-- Template de bouton HD_Btn_RedGrey_Stretch (largeur variable, partie centrale étirée)
function addon.ButtonTemplates.CreateHD_Btn_RedGrey_Stretch(parent, text, minWidth)
    local button = CreateFrame("Button", nil, parent)
    
    -- Largeur minimale par défaut
    local minimumWidth = minWidth or 150
    local buttonWidth = minimumWidth
    
    -- Configuration du texte d'abord pour pouvoir mesurer sa largeur
    local fontString = nil
    if text then
        button:SetText(text)
        button:SetNormalFontObject("GameFontNormal")
        fontString = button:GetFontString()
        fontString:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        
        -- Calculer la largeur nécessaire pour le texte avec une marge réduite
        local textWidth = fontString:GetStringWidth()
        local requiredWidth = textWidth + 40 -- 40px de marge pour les parties gauche/droite et padding
        buttonWidth = math.max(minimumWidth, requiredWidth)
    end
    
    button:SetSize(buttonWidth, 40)
    
    -- Calculer la largeur de la partie centrale
    local centerWidth = buttonWidth - 36 - 92 -- largeur totale - partie gauche - partie droite
    
    -- Partie gauche - état normal
    local leftNormalTexture = button:CreateTexture(nil, "BACKGROUND")
    leftNormalTexture:SetPoint("LEFT", button, "LEFT", 0, 0)
    leftNormalTexture:SetSize(36, 40)
    leftNormalTexture:SetAtlas("128-RedButton-Left")
    
    -- Partie centrale étirée - état normal
    local centerNormalTexture = button:CreateTexture(nil, "BACKGROUND")
    centerNormalTexture:SetPoint("LEFT", leftNormalTexture, "RIGHT", 0, 0)
    centerNormalTexture:SetSize(centerWidth, 40)
    centerNormalTexture:SetAtlas("_128-RedButton-Center")
    
    -- Partie droite - état normal
    local rightNormalTexture = button:CreateTexture(nil, "BACKGROUND")
    rightNormalTexture:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    rightNormalTexture:SetSize(92, 40)
    rightNormalTexture:SetAtlas("128-RedButton-Right")
    
    -- Partie gauche - état pressé
    local leftPushedTexture = button:CreateTexture(nil, "BACKGROUND")
    leftPushedTexture:SetPoint("LEFT", button, "LEFT", 0, 0)
    leftPushedTexture:SetSize(36, 40)
    leftPushedTexture:SetAtlas("128-RedButton-Left-Pressed")
    leftPushedTexture:Hide()
    
    -- Partie centrale étirée - état pressé
    local centerPushedTexture = button:CreateTexture(nil, "BACKGROUND")
    centerPushedTexture:SetPoint("LEFT", leftPushedTexture, "RIGHT", 0, 0)
    centerPushedTexture:SetSize(centerWidth, 40)
    centerPushedTexture:SetAtlas("_128-RedButton-Center-Pressed")
    centerPushedTexture:Hide()
    
    -- Partie droite - état pressé
    local rightPushedTexture = button:CreateTexture(nil, "BACKGROUND")
    rightPushedTexture:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    rightPushedTexture:SetSize(92, 40)
    rightPushedTexture:SetAtlas("128-RedButton-Right-Pressed")
    rightPushedTexture:Hide()
    
    -- Texture de survol pour l'ensemble du bouton
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetAtlas("128-RedButton-Highlight")
    button:SetHighlightTexture(highlightTexture)
    
    -- Gestion manuelle des états
    button:SetScript("OnMouseDown", function()
        leftNormalTexture:Hide()
        centerNormalTexture:Hide()
        rightNormalTexture:Hide()
        leftPushedTexture:Show()
        centerPushedTexture:Show()
        rightPushedTexture:Show()
    end)
    
    button:SetScript("OnMouseUp", function()
        leftPushedTexture:Hide()
        centerPushedTexture:Hide()
        rightPushedTexture:Hide()
        leftNormalTexture:Show()
        centerNormalTexture:Show()
        rightNormalTexture:Show()
    end)
    
    -- Fonction pour redimensionner le bouton avec un nouveau texte
    function button:UpdateTextAndResize(newText, newMinWidth)
        local newMinimum = newMinWidth or minimumWidth
        local newWidth = newMinimum
        
        if newText then
            button:SetText(newText)
            local textWidth = fontString:GetStringWidth()
            local requiredWidth = textWidth + 40 -- Marge réduite
            newWidth = math.max(newMinimum, requiredWidth)
        end
        
        local newCenterWidth = newWidth - 36 - 92
        button:SetSize(newWidth, 40)
        centerNormalTexture:SetSize(newCenterWidth, 40)
        centerPushedTexture:SetSize(newCenterWidth, 40)
    end
    
    -- Fonction pour redimensionner manuellement (conservée pour compatibilité)
    function button:ResizeButton(newWidth)
        local newCenterWidth = newWidth - 36 - 92
        button:SetSize(newWidth, 40)
        centerNormalTexture:SetSize(newCenterWidth, 40)
        centerPushedTexture:SetSize(newCenterWidth, 40)
    end
    
    
    -- Configuration finale du texte
    if text and fontString then
        fontString:SetTextColor(1, 1, 1, 1)
        fontString:SetPoint("CENTER", button, "CENTER", 0, 0)
        fontString:SetDrawLayer("OVERLAY", 1) -- Strate supérieure à HIGHLIGHT
    end
    
    return button
end