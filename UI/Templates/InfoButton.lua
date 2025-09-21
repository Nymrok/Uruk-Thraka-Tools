-- ============================================================================
-- Template de bouton InfoButton (bouton d'information)
-- ============================================================================

local addonName, addon = ...

-- Namespace pour les templates de boutons
addon.ButtonTemplates = addon.ButtonTemplates or {}

-- Template de bouton Info (bouton d'information avec icône info)
function addon.ButtonTemplates.CreateInfoButton(parent, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 28, size or 28)
    
    -- Texture normale (utiliser une icône d'information)
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetTexture("Interface\\Common\\help-i")
    button:SetNormalTexture(normalTexture)
    
    -- Texture pressée (légèrement différente)
    local pushedTexture = button:CreateTexture(nil, "BACKGROUND")
    pushedTexture:SetAllPoints()
    pushedTexture:SetTexture("Interface\\Common\\help-i")
    pushedTexture:SetVertexColor(0.8, 0.8, 0.8, 1)
    button:SetPushedTexture(pushedTexture)
    
    -- Texture de survol
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    highlightTexture:SetBlendMode("ADD")
    button:SetHighlightTexture(highlightTexture)
    
    return button
end