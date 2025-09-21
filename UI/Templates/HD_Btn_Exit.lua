-- ============================================================================
-- Template de bouton HD_Btn_Exit (bouton de sortie HD)
-- ============================================================================

local addonName, addon = ...

-- Namespace pour les templates de boutons
addon.ButtonTemplates = addon.ButtonTemplates or {}

-- Template de bouton "Croix"
function addon.ButtonTemplates.CreateHD_Btn_Exit(parent, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 26, size or 26)
    
    -- Texture normale
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetAtlas("128-RedButton-Exit")
    button:SetNormalTexture(normalTexture)
    
    -- Texture pressée
    local pushedTexture = button:CreateTexture(nil, "BACKGROUND")
    pushedTexture:SetAllPoints()
    pushedTexture:SetAtlas("128-RedButton-Exit-Pressed")
    button:SetPushedTexture(pushedTexture)
    
    -- Texture de survol
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetAtlas("128-RedButton-Cart-Add-Highlight")
    button:SetHighlightTexture(highlightTexture)
    
    -- Texture désactivée
    local disabledTexture = button:CreateTexture(nil, "BACKGROUND")
    disabledTexture:SetAllPoints()
    disabledTexture:SetAtlas("128-RedButton-Exit-Disabled")
    button:SetDisabledTexture(disabledTexture)
    
    return button
end