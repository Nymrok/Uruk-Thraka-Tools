-- ============================================================================
-- Interface utilisateur principale de l'addon
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée
local addonName, addon = ...

-- Table pour stocker les fonctions UI
addon.UI = {}

-- Configuration du fond adaptatif selon classe/spécialisation
local function GetBackgroundAtlas()
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    local textures = {
        DRUID = {"talents-background-druid-balance", "talents-background-druid-feral", "talents-background-druid-guardian", "talents-background-druid-restoration"},
        WARRIOR = {"talents-background-warrior-arms", "talents-background-warrior-fury", "talents-background-warrior-protection"},
        PALADIN = {"talents-background-paladin-holy", "talents-background-paladin-protection", "talents-background-paladin-retribution"},
        HUNTER = {"talents-background-hunter-beastmastery", "talents-background-hunter-marksmanship", "talents-background-hunter-survival"},
        ROGUE = {"talents-background-rogue-assassination", "talents-background-rogue-outlaw", "talents-background-rogue-subtlety"},
        PRIEST = {"talents-background-priest-discipline", "talents-background-priest-holy", "talents-background-priest-shadow"},
        DEATHKNIGHT = {"talents-background-deathknight-blood", "talents-background-deathknight-frost", "talents-background-deathknight-unholy"},
        SHAMAN = {"talents-background-shaman-elemental", "talents-background-shaman-enhancement", "talents-background-shaman-restoration"},
        MAGE = {"talents-background-mage-arcane", "talents-background-mage-fire", "talents-background-mage-frost"},
        WARLOCK = {"talents-background-warlock-affliction", "talents-background-warlock-demonology", "talents-background-warlock-destruction"},
        MONK = {"talents-background-monk-brewmaster", "talents-background-monk-mistweaver", "talents-background-monk-windwalker"},
        DEMONHUNTER = {"talents-background-demonhunter-havoc", "talents-background-demonhunter-vengeance"},
        EVOKER = {"talents-background-evoker-devastation", "talents-background-evoker-preservation", "talents-background-evoker-augmentation"}
    }
    return (textures[class] and textures[class][spec]) or "completiondialog-dragonflightcampaign-background"
end

-- Création de la fenêtre principale
local function CreateMainFrame()
    -- Création de la frame principale
    local frame = CreateFrame("Frame", "UTT_MainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(800, 400)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(100)
    
    -- Configuration de déplacement
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true) -- Empêche la frame de sortir de l'écran
    
    -- Fond rose pastel pour la frame principale
    local mainFrameBackground = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    mainFrameBackground:SetAllPoints(frame)
    mainFrameBackground:SetColorTexture(1, 0.75, 0.8, 0) -- Rose pastel
    
    -- Création du fond adaptatif
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
    bgTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    bgTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    
    local atlas = GetBackgroundAtlas()
    bgTexture:SetAtlas(atlas, true)
    bgTexture:SetTexCoord(0, 1, 0, 1)
    bgTexture:SetVertexColor(1, 1, 1, 1)
    
    -- Stocker la référence du bgTexture pour pouvoir la mettre à jour
    frame.bgTexture = bgTexture
    
    -- ========================================================================
    -- BORDURE : ANGLES
    -- ========================================================================

    local topLeftCorner = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    topLeftCorner:SetAtlas("GenericMetal2-NineSlice-CornerTopLeft", true)
    topLeftCorner:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topLeftCorner:SetSize(40, 40)

    local topRightCorner = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    topRightCorner:SetAtlas("GenericMetal2-NineSlice-CornerTopRight", true)
    topRightCorner:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topRightCorner:SetSize(40, 40)

    local bottomLeftCorner = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    bottomLeftCorner:SetAtlas("GenericMetal2-NineSlice-CornerBottomLeft", true)
    bottomLeftCorner:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottomLeftCorner:SetSize(40, 40)

    local bottomRightCorner = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    bottomRightCorner:SetAtlas("GenericMetal2-NineSlice-CornerBottomRight", true)
    bottomRightCorner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottomRightCorner:SetSize(40, 40)
    
    -- ========================================================================
    -- BORDURE : LIGNES
    -- ========================================================================

    local topBorder = frame:CreateTexture(nil, "BORDER", nil, 5)
    topBorder:SetAtlas("_GenericMetal2-NineSlice-EdgeTop", true)
    topBorder:SetPoint("TOPLEFT", topLeftCorner, "TOPRIGHT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", topRightCorner, "TOPLEFT", 0, 0)
    topBorder:SetHeight(40)
    
    local bottomBorder = frame:CreateTexture(nil, "BORDER", nil, 5)
    bottomBorder:SetAtlas("_GenericMetal2-NineSlice-EdgeBottom", true)
    bottomBorder:SetPoint("BOTTOMLEFT", bottomLeftCorner, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", bottomRightCorner, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetHeight(40)

    local leftBorder = frame:CreateTexture(nil, "BORDER", nil, 5)
    leftBorder:SetAtlas("!GenericMetal2-NineSlice-EdgeLeft", true)
    leftBorder:SetPoint("TOPLEFT", topLeftCorner, "BOTTOMLEFT", 0, 0)
    leftBorder:SetPoint("BOTTOMLEFT", bottomLeftCorner, "TOPLEFT", 0, 0)
    leftBorder:SetWidth(40)

    local rightBorder = frame:CreateTexture(nil, "BORDER", nil, 5)
    rightBorder:SetAtlas("!GenericMetal2-NineSlice-EdgeRight", true)
    rightBorder:SetPoint("TOPRIGHT", topRightCorner, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", bottomRightCorner, "TOPRIGHT", 0, 0)
    rightBorder:SetWidth(40)

    -- ========================================================================
    -- BOUTONS
    -- ========================================================================

    local refreshButton = addon.ButtonTemplates.CreateHD_Btn_Refresh(frame)
    refreshButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, 0)
    refreshButton:SetScript("OnClick", function()
        ReloadUI()
    end)
    refreshButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Recharger l'interface", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    refreshButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local closeButton = addon.ButtonTemplates.CreateHD_Btn_Exit(frame)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    closeButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Fermer l'addon", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    closeButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- ========================================================================
    -- COMPOSANTS
    -- ========================================================================

    -- Création de UTT_Nav
    local navFrame = CreateFrame("Frame", "UTT_Nav", frame)
    navFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -22)
    navFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 22)
    navFrame:SetWidth(150)
    
    -- Configuration du déplacement pour UTT_Nav (transmet au parent)
    navFrame:EnableMouse(true)
    navFrame:RegisterForDrag("LeftButton")
    navFrame:SetScript("OnDragStart", function() frame:StartMoving() end)
    navFrame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    -- Création de UTT_Display
    local displayFrame = CreateFrame("Frame", "UTT_Display", frame)
    displayFrame:SetPoint("TOPLEFT", navFrame, "TOPRIGHT", 0, 0)
    displayFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 22)

    -- Configuration du déplacement pour UTT_Display (transmet au parent)
    displayFrame:EnableMouse(true)
    displayFrame:RegisterForDrag("LeftButton")
    displayFrame:SetScript("OnDragStart", function() frame:StartMoving() end)
    displayFrame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    -- Stockage des références pour un accès facile plus tard
    frame.navFrame = navFrame
    frame.displayFrame = displayFrame
    
    -- Initialisation de la navigation
    addon.Nav:Init(navFrame)
    
    -- Cacher la fenêtre par défaut
    frame:Hide()

    -- Gestion de la touche ÉCHAP
    tinsert(UISpecialFrames, "UTT_MainFrame")
    
    return frame
end

-- Initialisation de l'interface
function addon.UI:Init()
    self.mainFrame = CreateMainFrame()
end

-- Fonctions pour afficher/masquer la fenêtre
function addon.UI:Show()
    -- Utiliser directement la frame globale si elle existe
    local mainFrame = _G["UTT_MainFrame"]
    if not mainFrame then
        -- Sinon, l'initialiser une seule fois
        if not self.mainFrame then
            self:Init()
        end
        mainFrame = self.mainFrame
    end
    
    -- Mettre à jour le fond adaptatif à chaque ouverture
    if mainFrame and mainFrame.bgTexture then
        local atlas = GetBackgroundAtlas()
        mainFrame.bgTexture:SetAtlas(atlas, true)
    end
    
    mainFrame:Show()
end

function addon.UI:Hide()
    local mainFrame = _G["UTT_MainFrame"]
    if mainFrame then
        mainFrame:Hide()
    end
end

-- Fonction pour l'Addon Compartment
function UTT_AC()
    addon.UI:Show()
end
