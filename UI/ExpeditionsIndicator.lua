-- ============================================================================
-- Widget d'affichage du statut des expéditions avec interface déplaçable
-- ============================================================================

local addonName, addon = ...

addon.ExpeditionsIndicator = {}

-- ============================================================================
-- ÉTAT PRIVÉ
-- ============================================================================
local indicatorFrame = nil
local isDragging = false

-- ============================================================================
-- FONCTIONS PRIVÉES
-- ============================================================================

--[[
    Crée l'indicateur visuel principal
]]
local function createIndicator()
    if indicatorFrame then return indicatorFrame end
    
    -- Frame principale draggable
    indicatorFrame = CreateFrame("Button", "UTT_ExpeditionsIndicator", UIParent)
    indicatorFrame:SetSize(80, 80)
    indicatorFrame:SetPoint("CENTER", UIParent, "CENTER", 200, -100)
    indicatorFrame:SetMovable(true)
    indicatorFrame:SetClampedToScreen(true)
    indicatorFrame:EnableMouse(true)
    indicatorFrame:RegisterForDrag("LeftButton")
    
    -- Background circle
    local bg = indicatorFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetAtlas("common-radiobutton-circle")
    bg:SetVertexColor(0.3, 0.3, 0.3, 0.8)
    
    -- Texture pour le numéro
    local numberTexture = indicatorFrame:CreateTexture(nil, "OVERLAY")
    numberTexture:SetSize(48, 48)
    numberTexture:SetPoint("CENTER")
    
    -- Texte de fallback si atlas non disponible
    local numberText = indicatorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    numberText:SetPoint("CENTER")
    numberText:SetTextColor(1, 0.8, 0, 1) -- Doré
    
    indicatorFrame.numberTexture = numberTexture
    indicatorFrame.numberText = numberText
    
    -- Scripts de déplacement
    indicatorFrame:SetScript("OnDragStart", function()
        isDragging = true
        indicatorFrame:StartMoving()
        -- Masquer tooltip pendant déplacement
        GameTooltip:Hide()
    end)
    
    indicatorFrame:SetScript("OnDragStop", function()
        indicatorFrame:StopMovingOrSizing()
        addon.ExpeditionsIndicator:SavePosition()
        -- Délai pour éviter clic après drag
        C_Timer.After(0.1, function() 
            isDragging = false 
        end)
    end)
    
    -- Clic = ouvrir interface sur page Expeditions
    indicatorFrame:SetScript("OnClick", function()
        if not isDragging then
            if addon.UI and addon.UI.mainFrame then
                if addon.UI.mainFrame:IsShown() then
                    -- Si l'interface est déjà ouverte, vérifier si on est sur Expeditions
                    if addon.Nav and addon.Nav:GetCurrentPageId() == "Expeditions" then
                        -- Si déjà sur Expeditions, fermer l'interface
                        addon.UI:Hide()
                    else
                        -- Sinon, naviguer vers Expeditions
                        addon.Nav:SelectPage("Expeditions", false)
                    end
                else
                    -- Interface fermée : ouvrir ET naviguer vers Expeditions
                    addon.UI:Show()
                    if addon.Nav then
                        addon.Nav:SelectPage("Expeditions", false)
                    end
                end
            end
        end
    end)
    
    -- Tooltip informatif
    indicatorFrame:SetScript("OnEnter", function(self)
        if isDragging then return end
        
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Expéditions UTT", 1, 0.8, 0, 1, true)
        
        local count = addon.ExpeditionsService:GetAvailableCount()
        if count > 0 then
            GameTooltip:AddLine(count .. " expédition(s) disponible(s)", 0.2, 1, 0.2, true)
        else
            GameTooltip:AddLine("Aucune expédition disponible", 0.7, 0.7, 0.7, true)
        end
        
        GameTooltip:AddLine("Cliquez pour ouvrir l'interface", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("Glissez pour déplacer", 0.5, 0.5, 1, true)
        GameTooltip:Show()
    end)
    
    indicatorFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    indicatorFrame:Hide()
    return indicatorFrame
end

-- ============================================================================
-- API PUBLIQUE
-- ============================================================================

--[[
    Crée l'indicateur (si pas déjà fait)
    @return Frame - Le frame de l'indicateur
]]
function addon.ExpeditionsIndicator:Create()
    return createIndicator()
end

--[[
    Met à jour l'affichage de l'indicateur
    @param count number - Nombre d'expéditions disponibles
]]
function addon.ExpeditionsIndicator:Update(count)
    local frame = createIndicator()
    
    if count > 0 and addon.ExpeditionsService:IsEnabled() then
        -- Essayer d'utiliser l'atlas Blizzard
        local atlasName = "services-number-" .. math.min(count, 9)
        if frame.numberTexture and C_Texture.GetAtlasInfo(atlasName) then
            frame.numberTexture:SetAtlas(atlasName)
            frame.numberTexture:Show()
            frame.numberText:Hide()
        else
            -- Fallback texte si atlas non disponible
            frame.numberTexture:Hide()
            frame.numberText:SetText(tostring(count))
            frame.numberText:Show()
        end
        
        frame:Show()
    else
        frame:Hide()
    end
end

--[[
    Affiche l'indicateur (même si 0 expédition, pour debug)
]]
function addon.ExpeditionsIndicator:Show()
    local frame = createIndicator()
    frame:Show()
end

--[[
    Masque l'indicateur
]]
function addon.ExpeditionsIndicator:Hide()
    if indicatorFrame then
        indicatorFrame:Hide()
    end
end

--[[
    Sauvegarde la position actuelle de l'indicateur
]]
function addon.ExpeditionsIndicator:SavePosition()
    if indicatorFrame then
        local point, _, relPoint, x, y = indicatorFrame:GetPoint()
        addon:EnsureUTTData()
        if not UTT_Data.ExpeditionsIndicatorPosition then
            UTT_Data.ExpeditionsIndicatorPosition = {}
        end
        
        UTT_Data.ExpeditionsIndicatorPosition = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y
        }
    end
end

--[[
    Restaure la position sauvegardée de l'indicateur
]]
function addon.ExpeditionsIndicator:RestorePosition()
    if not indicatorFrame then return end
    
    addon:EnsureUTTData()
    local pos = UTT_Data.ExpeditionsIndicatorPosition
    if pos and pos.point and pos.relPoint then
        indicatorFrame:ClearAllPoints()
        indicatorFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x or 0, pos.y or 0)
    end
end

--[[
    Définit manuellement la position de l'indicateur
    @param x number - Position X
    @param y number - Position Y
]]
function addon.ExpeditionsIndicator:SetPosition(x, y)
    local frame = createIndicator()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    self:SavePosition()
end

-- ============================================================================
-- INITIALISATION
-- ============================================================================

--[[
    Initialise l'indicateur d'expéditions
]]
function addon.ExpeditionsIndicator:Init()
    createIndicator()
    self:RestorePosition()
    
    -- Écouter les changements du service ExpeditionsService
    if addon.ExpeditionsService then
        addon.ExpeditionsService:OnChange(function()
            local count = addon.ExpeditionsService:GetAvailableCount()
            addon.ExpeditionsIndicator:Update(count)
        end)
        
        -- Callbacks pour notifications (optionnel - pour feedback utilisateur)
        addon.ExpeditionsService:OnAvailable(function(questID, questName)
            print("|cFF00FF00[UTT]|r Expédition disponible : " .. questName)
        end)
        
        addon.ExpeditionsService:OnUnavailable(function(questID, questName)
            print("|cFFFFAA00[UTT]|r Expédition terminée : " .. questName)
        end)
    end
    
    -- Mise à jour initiale
    local initialCount = addon.ExpeditionsService and addon.ExpeditionsService:GetAvailableCount() or 0
    self:Update(initialCount)
end
