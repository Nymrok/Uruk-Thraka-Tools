-- ============================================================================
-- Template de bouton AddButtonSD (bouton d'ajout standard avec icône plus)
-- ============================================================================

local addonName, addon = ...

-- Namespace pour les templates de boutons
addon.ButtonTemplates = addon.ButtonTemplates or {}

-- Template de bouton AddButtonSD (bouton d'ajout avec icône plus - version standard)
function addon.ButtonTemplates.CreateAddButtonSD(parent, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 28, size or 28)
    
    -- Texture normale
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetAtlas("glues-characterSelect-icon-plus")
    button:SetNormalTexture(normalTexture)
    
    -- Texture pressée
    local pushedTexture = button:CreateTexture(nil, "BACKGROUND")
    pushedTexture:SetAllPoints()
    pushedTexture:SetAtlas("glues-characterSelect-icon-plus-pressed")
    button:SetPushedTexture(pushedTexture)
    
    -- Texture de survol
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetAtlas("glues-characterSelect-icon-plus-hover")
    button:SetHighlightTexture(highlightTexture)
    
    return button
end