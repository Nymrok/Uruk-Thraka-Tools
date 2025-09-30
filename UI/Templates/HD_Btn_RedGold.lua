-- ============================================================================
-- Template de bouton HD_Btn_RedGold
-- ============================================================================

local addonName, addon = ...

-- Namespace pour les templates de boutons
addon.ButtonTemplates = addon.ButtonTemplates or {}

-- Template de bouton HD_Btn_RedGold (composé de deux parties)
function addon.ButtonTemplates.CreateHD_Btn_RedGold(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 130, height or 40)
    
    -- Proportions réelles des atlas : Left 28.1% | Right 71.9%
    local totalWidth = width or 130
    local leftWidth = totalWidth * 0.281  -- 28.1%
    local rightWidth = totalWidth * 0.719 -- 71.9%
    
    -- Partie gauche - état normal
    local leftNormalTexture = button:CreateTexture(nil, "BACKGROUND")
    leftNormalTexture:SetPoint("LEFT", button, "LEFT", 0, 0)
    leftNormalTexture:SetSize(leftWidth, height or 40)
    leftNormalTexture:SetAtlas("128-GoldRedButton-Left")
    
    -- Partie droite - état normal
    local rightNormalTexture = button:CreateTexture(nil, "BACKGROUND")
    rightNormalTexture:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    rightNormalTexture:SetSize(rightWidth, height or 40)
    rightNormalTexture:SetAtlas("128-GoldRedButton-Right")
    
    -- Partie gauche - état pressé
    local leftPushedTexture = button:CreateTexture(nil, "BACKGROUND")
    leftPushedTexture:SetPoint("LEFT", button, "LEFT", 0, 0)
    leftPushedTexture:SetSize(leftWidth, height or 40)
    leftPushedTexture:SetAtlas("128-GoldRedButton-Left-Pressed")
    leftPushedTexture:Hide()
    
    -- Partie droite - état pressé
    local rightPushedTexture = button:CreateTexture(nil, "BACKGROUND")
    rightPushedTexture:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    rightPushedTexture:SetSize(rightWidth, height or 40)
    rightPushedTexture:SetAtlas("128-GoldRedButton-Right-Pressed")
    rightPushedTexture:Hide()
    
    -- Texture de survol pour l'ensemble du bouton
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetAtlas("128-GoldRedButton-Highlight")
    button:SetHighlightTexture(highlightTexture)
    
    -- Gestion manuelle des états
    button:SetScript("OnMouseDown", function()
        leftNormalTexture:Hide()
        rightNormalTexture:Hide()
        leftPushedTexture:Show()
        rightPushedTexture:Show()
    end)
    
    button:SetScript("OnMouseUp", function()
        leftPushedTexture:Hide()
        rightPushedTexture:Hide()
        leftNormalTexture:Show()
        rightNormalTexture:Show()
    end)
    
    -- Configuration du texte
    if text then
        button:SetText(text)
        button:SetNormalFontObject("GameFontNormal")
        local fontString = button:GetFontString()
        fontString:SetTextColor(1, 1, 1, 1)
        fontString:SetPoint("CENTER", button, "CENTER", 0, 0)
        fontString:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        fontString:SetDrawLayer("OVERLAY", 1) -- Strate supérieure à HIGHLIGHT
    end
    
    return button
end