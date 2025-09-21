-- ============================================================================
-- Template de bouton HD_Btn_VisibilityOn (bouton de vue avec icône œil)
-- ============================================================================

local addonName, addon = ...

-- Namespace pour les templates de boutons
addon.ButtonTemplates = addon.ButtonTemplates or {}

-- Template de bouton "Œil"
function addon.ButtonTemplates.CreateHD_Btn_VisibilityOn(parent, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 40, size or 40)

    -- Texture normale
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetAtlas("128-RedButton-VisibilityOn")
    button:SetNormalTexture(normalTexture)
    
    -- Texture pressée
    local pushedTexture = button:CreateTexture(nil, "BACKGROUND")
    pushedTexture:SetAllPoints()
    pushedTexture:SetAtlas("128-RedButton-VisibilityOn-Pressed")
    button:SetPushedTexture(pushedTexture)
    
    -- Texture de survol
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetAtlas("128-RedButton-VisibilityOn-Highlight")
    button:SetHighlightTexture(highlightTexture)
    
    -- Texture désactivée
    local disabledTexture = button:CreateTexture(nil, "BACKGROUND")
    disabledTexture:SetAllPoints()
    disabledTexture:SetAtlas("128-RedButton-VisibilityOn-Disabled")
    button:SetDisabledTexture(disabledTexture)
    
    return button
end