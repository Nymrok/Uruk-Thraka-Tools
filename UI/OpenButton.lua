-- ============================================================================
-- Bouton d'interface pour afficher/masquer la fenêtre principale
-- ============================================================================

local _, addon = ...

-- Module OpenButton
addon.OpenButton = {}

-- Variables locales
local openButton = nil

-- ============================================================================
-- FONCTIONS PRIVÉES
-- ============================================================================

--[[
    Sauvegarde la position du bouton
]]
local function SaveButtonPosition()
    if not openButton then return end
    
    -- Initialiser la table de sauvegarde si elle n'existe pas
    if not UTT_Data then
        UTT_Data = {}
    end
    if not UTT_Data.OpenButton then
        UTT_Data.OpenButton = {}
    end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = openButton:GetPoint()
    UTT_Data.OpenButton = {
        point = point,
        relativePoint = relativePoint,
        xOffset = xOfs,
        yOffset = yOfs
    }
end

--[[
    Restaure la position sauvegardée du bouton
]]
local function RestoreButtonPosition()
    if not openButton or not UTT_Data or not UTT_Data.OpenButton then
        return false
    end
    
    local pos = UTT_Data.OpenButton
    if pos.point and pos.relativePoint and pos.xOffset and pos.yOffset then
        openButton:ClearAllPoints()
        openButton:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOffset, pos.yOffset)
        return true
    end
    
    return false
end

--[[
    Crée le bouton d'ouverture/fermeture de l'interface
]]
local function CreateOpenButton()
    if openButton then
        return -- Bouton déjà créé
    end
    
    -- Créer un bouton simple avec le logo UTT
    openButton = CreateFrame("Button", nil, UIParent)
    openButton:SetSize(28, 28) -- Taille carrée pour le logo
    
    -- Essayer de restaurer la position sauvegardée
    if not RestoreButtonPosition() then
        -- Position par défaut si aucune sauvegarde
        if ChatFrame1Tab then
            openButton:SetPoint("RIGHT", ChatFrame1Tab, "LEFT", -5, 5)
        else
            -- Fallback si ChatFrame1Tab n'existe pas
            openButton:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 100)
            print("|cFFFFAA00[UTT]|r ChatFrame1Tab non trouvé, bouton UTT positionné en fallback")
        end
    end
    
    -- Ajouter le logo UTT comme texture normale
    local logoTexture = openButton:CreateTexture(nil, "ARTWORK")
    logoTexture:SetAllPoints(openButton)
    logoTexture:SetTexture("Interface\\AddOns\\UrukThrakaTools\\Logo.tga")
    openButton:SetNormalTexture(logoTexture)
    
    -- Texture de survol (logo légèrement plus lumineux)
    local highlightTexture = openButton:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints(openButton)
    highlightTexture:SetTexture("Interface\\AddOns\\UrukThrakaTools\\Logo.tga")
    highlightTexture:SetVertexColor(1.2, 1.2, 1.2, 1) -- Plus lumineux au survol
    openButton:SetHighlightTexture(highlightTexture)
    
    -- Texture pressée (logo légèrement plus sombre)
    local pushedTexture = openButton:CreateTexture(nil, "ARTWORK")
    pushedTexture:SetAllPoints(openButton)
    pushedTexture:SetTexture("Interface\\AddOns\\UrukThrakaTools\\Logo.tga")
    pushedTexture:SetVertexColor(0.8, 0.8, 0.8, 1) -- Plus sombre quand pressé
    openButton:SetPushedTexture(pushedTexture)
    
    -- Configuration pour le déplacement
    openButton:SetMovable(true)
    openButton:EnableMouse(true)
    openButton:RegisterForDrag("LeftButton")
    openButton:SetClampedToScreen(true) -- Empêche de sortir de l'écran
    
    -- Variable pour gérer le déplacement vs clic
    local isDragging = false
    
    -- Scripts de déplacement
    openButton:SetScript("OnDragStart", function(self)
        isDragging = true
        self:StartMoving()
        -- Masquer le tooltip pendant le déplacement
        GameTooltip:Hide()
    end)
    
    openButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        
        -- Sauvegarder la nouvelle position
        SaveButtonPosition()
        
        -- Délai pour éviter le clic après déplacement
        C_Timer.After(0.1, function()
            isDragging = false
        end)
    end)
    
    -- Gestion du clic : toggle de la MainUI (seulement si pas de déplacement)
    openButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" and not isDragging then
            -- Vérifier si l'interface principale est affichée
            if addon.UI and addon.UI.mainFrame and addon.UI.mainFrame:IsShown() then
                -- Interface visible -> la masquer
                addon.UI:Hide()
            else
                -- Interface cachée -> l'afficher
                if addon.UI and addon.UI.Show then
                    addon.UI:Show()
                else
                    print("|cFFFF0000[UTT]|r Erreur : Module UI non disponible")
                end
            end
        end
    end)
    
    -- Tooltip informatif
    openButton:SetScript("OnEnter", function(self)
        -- Ne pas afficher le tooltip pendant le déplacement
        if isDragging then return end
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Uruk Thraka Tools", 1, 1, 1, 1, true)
        GameTooltip:AddLine("Glissez pour déplacer le bouton", 0.5, 0.5, 1, true)
        GameTooltip:Show()
    end)
    
    openButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

-- ============================================================================
-- FONCTIONS PUBLIQUES (API du module)
-- ============================================================================

--[[
    Initialise le module OpenButton
]]
function addon.OpenButton:Init()
    -- Le bouton sera créé à PLAYER_ENTERING_WORLD
end

--[[
    Affiche le bouton d'ouverture
]]
function addon.OpenButton:Show()
    if openButton then
        openButton:Show()
    end
end

--[[
    Masque le bouton d'ouverture
]]
function addon.OpenButton:Hide()
    if openButton then
        openButton:Hide()
    end
end

--[[
    Vérifie si le bouton existe
]]
function addon.OpenButton:Exists()
    return openButton ~= nil
end

-- ============================================================================
-- GESTION DES ÉVÉNEMENTS
-- ============================================================================

-- Frame pour gérer les événements
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Délai pour s'assurer que tous les modules sont chargés
        C_Timer.After(2, function()
            CreateOpenButton()
        end)
        
        -- Ne plus écouter cet événement une fois le bouton créé
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
