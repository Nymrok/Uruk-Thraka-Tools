-- ============================================================================
-- CORE - CONSTANTS
-- ============================================================================
-- Constantes de couleurs centralisées pour tout l'addon
-- ============================================================================

local addonName, addon = ...

-- ============================================================================
-- COULEURS STANDARDISÉES
-- ============================================================================

addon.Colors = {
    -- États de disponibilité
    AVAILABLE = {r = 0.2, g = 1.0, b = 0.2, a = 1, hex = "|cFF33FF33"},      -- Vert vif pour disponible
    UNAVAILABLE = {r = 0.9, g = 0.9, b = 0.9, a = 1, hex = "|cFFE6E6E6"},    -- Blanc pour non disponible
    
    -- Messages système
    SUCCESS = {r = 0.0, g = 1.0, b = 0.0, a = 1, hex = "|cFF00FF00"},        -- Vert succès
    ERROR = {r = 1.0, g = 0.0, b = 0.0, a = 1, hex = "|cFFFF0000"},          -- Rouge erreur
    WARNING = {r = 1.0, g = 1.0, b = 0.0, a = 1, hex = "|cFFFFFF00"},        -- Jaune avertissement
    INFO = {r = 0.2, g = 0.8, b = 1.0, a = 1, hex = "|cFF33CCFF"},           -- Bleu information
    
    -- États d'interface
    NORMAL = {r = 0.9, g = 0.9, b = 0.9, a = 1, hex = "|cFFE6E6E6"},         -- Texte normal
    DISABLED = {r = 0.4, g = 0.4, b = 0.4, a = 1, hex = "|cFF666666"},       -- Texte désactivé
    MUTED = {r = 0.7, g = 0.7, b = 0.7, a = 1, hex = "|cFFB3B3B3"},          -- Texte secondaire
    
    -- Éléments spéciaux
    GOLD = {r = 1.0, g = 0.8, b = 0.0, a = 1, hex = "|cFFFFC000"},           -- Or WoW standard
    ADDON_PREFIX = {r = 0.2, g = 0.67, b = 0.2, a = 1, hex = "|cFF33AA33"},  -- Vert addon UTT
    
    -- Transparence pour ID
    ID_TRANSPARENCY = 0.5
}

-- ============================================================================
-- TEXTURES STANDARDISÉES
-- ============================================================================

addon.Textures = {
    -- Séparateurs
    SEPARATOR_SIMPLE = "Interface\\Common\\UI-TooltipDivider-Transparent",
    
    -- Bordures d'icônes
    ICON_BORDER = "Interface\\Common\\WhiteIconFrame",
    
    -- Icônes par défaut
    DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark",
    EXPEDITION_ICON = "Mobile-QuestIcon-Desaturated",
    
    -- Surlignage
    HIGHLIGHT = "Interface\\Buttons\\UI-Common-MouseHilight"
}

-- ============================================================================
-- PRÉRÉGLAGES COULEURS FRÉQUENTS
-- ============================================================================

-- Fonction utilitaire pour appliquer les couleurs RGB
function addon.Colors:ApplyRGB(fontString, colorKey)
    local color = self[colorKey]
    if color and fontString then
        fontString:SetTextColor(color.r, color.g, color.b, color.a)
    end
end

-- Fonction utilitaire pour obtenir les valeurs RGB
function addon.Colors:GetRGB(colorKey)
    local color = self[colorKey]
    if color then
        return color.r, color.g, color.b, color.a
    end
    return 1, 1, 1, 1 -- Blanc par défaut
end

-- Fonction utilitaire pour obtenir le code hexadécimal
function addon.Colors:GetHex(colorKey)
    local color = self[colorKey]
    return color and color.hex or "|cFFFFFFFF"
end
