-- ============================================================================
-- Service de vente automatique des objets de qualité grise
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée entre tous les fichiers
local addonName, addon = ...

-- Module de vente automatique des objets gris
addon.AutoSellGrey = {}

-- Frame pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- ============================================================================
-- FONCTIONS PRIVÉES (Mécanique interne)
-- ============================================================================

-- Fonction pour vendre automatiquement les objets gris
local function ProcessAutoSellGrey()
    if not addon.AutoSellGrey:IsEnabled() then
        return
    end

    if not (MerchantFrame and MerchantFrame:IsVisible()) then
        return
    end
    
    if C_MerchantFrame.IsSellAllJunkEnabled() then
        C_MerchantFrame.SellAllJunkItems()
    end
end

-- ============================================================================
-- FONCTIONS PUBLIQUES (API du module)
-- ============================================================================

function addon.AutoSellGrey:IsEnabled()
    return UTT_Data and UTT_Data.autoSellGreyEnabled or false
end

function addon.AutoSellGrey:Enable()
    addon:EnsureUTTData()
    UTT_Data.autoSellGreyEnabled = true
    eventFrame:RegisterEvent("MERCHANT_SHOW")
end

function addon.AutoSellGrey:Disable()
    addon:EnsureUTTData()
    UTT_Data.autoSellGreyEnabled = false
    eventFrame:UnregisterEvent("MERCHANT_SHOW")
end

-- ============================================================================
-- INITIALISATION ET ÉVÉNEMENTS
-- ============================================================================

function addon.AutoSellGrey:Init()
    addon:EnsureUTTData()
    if UTT_Data.autoSellGreyEnabled == nil then
        UTT_Data.autoSellGreyEnabled = false
    end
    
    if UTT_Data.autoSellGreyEnabled then
        eventFrame:RegisterEvent("MERCHANT_SHOW")
    end
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "MERCHANT_SHOW" then
            C_Timer.After(0.3, ProcessAutoSellGrey)
        end
    end)
end
