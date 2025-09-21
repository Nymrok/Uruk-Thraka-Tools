-- ============================================================================
-- Service de réparation automatique des objets endommagés
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée entre tous les fichiers
local addonName, addon = ...

-- Module de réparation automatique
addon.AutoRepair = {}

-- Frame pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- ============================================================================
-- FONCTIONS PRIVÉES (Mécanique interne)
-- ============================================================================

-- Fonction pour réparer automatiquement l'équipement
local function ProcessAutoRepair()
    if not addon.AutoRepair:IsEnabled() then
        return
    end

    if not (MerchantFrame and MerchantFrame:IsVisible()) then
        return
    end
    
    if CanMerchantRepair() then
        RepairAllItems()
    end
end

-- ============================================================================
-- FONCTIONS PUBLIQUES (API du module)
-- ============================================================================

function addon.AutoRepair:IsEnabled()
    return UTT_Data and UTT_Data.autoRepairEnabled or false
end

function addon.AutoRepair:Enable()
    addon:EnsureUTTData()
    UTT_Data.autoRepairEnabled = true
    eventFrame:RegisterEvent("MERCHANT_SHOW")
end

function addon.AutoRepair:Disable()
    addon:EnsureUTTData()
    UTT_Data.autoRepairEnabled = false
    eventFrame:UnregisterEvent("MERCHANT_SHOW")
end

-- ============================================================================
-- INITIALISATION ET ÉVÉNEMENTS
-- ============================================================================

function addon.AutoRepair:Init()
    addon:EnsureUTTData()
    if UTT_Data.autoRepairEnabled == nil then
        UTT_Data.autoRepairEnabled = false
    end
    
    if UTT_Data.autoRepairEnabled then
        eventFrame:RegisterEvent("MERCHANT_SHOW")
    end
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "MERCHANT_SHOW" then
            C_Timer.After(0.3, ProcessAutoRepair)
        end
    end)
end
