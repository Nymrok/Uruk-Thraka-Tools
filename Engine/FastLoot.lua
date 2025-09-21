-- ============================================================================
-- Service d'accélération automatique du butin
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée entre tous les fichiers
local addonName, addon = ...

-- Module de butin rapide
addon.FastLoot = {}

-- Frame pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- ============================================================================
-- FONCTIONS PRIVÉES (Mécanique interne)
-- ============================================================================

-- Fonction pour ramasser rapidement le butin
local function ProcessFastLoot()
    if not addon.FastLoot:IsEnabled() then
        return
    end
    
    for i = GetNumLootItems(), 1, -1 do
        local lootIcon, lootName, lootQuantity, currencyID, lootQuality = GetLootSlotInfo(i)
        if lootName then
            LootSlot(i)
        end
    end
end

-- ============================================================================
-- FONCTIONS PUBLIQUES (API du module)
-- ============================================================================

function addon.FastLoot:IsEnabled()
    return UTT_Data and UTT_Data.fastLootEnabled or false
end

function addon.FastLoot:Enable()
    addon:EnsureUTTData()
    UTT_Data.fastLootEnabled = true
    SetCVar("autoLootDefault", "1")
    eventFrame:RegisterEvent("LOOT_READY")
    eventFrame:RegisterEvent("LOOT_OPENED")
end

function addon.FastLoot:Disable()
    addon:EnsureUTTData()
    UTT_Data.fastLootEnabled = false
    eventFrame:UnregisterEvent("LOOT_READY")
    eventFrame:UnregisterEvent("LOOT_OPENED")
end

-- ============================================================================
-- INITIALISATION ET ÉVÉNEMENTS
-- ============================================================================

function addon.FastLoot:Init()
    addon:EnsureUTTData()
    if UTT_Data.fastLootEnabled == nil then
        UTT_Data.fastLootEnabled = false
    end
    
    if UTT_Data.fastLootEnabled then
        SetCVar("autoLootDefault", "1")
        eventFrame:RegisterEvent("LOOT_READY")
        eventFrame:RegisterEvent("LOOT_OPENED")
    end
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "LOOT_READY" then
            C_Timer.After(0.1, ProcessFastLoot)
        elseif event == "LOOT_OPENED" then
            if GetCVar("autoLootDefault") ~= "1" then
                SetCVar("autoLootDefault", "1")
            end
        end
    end)
end
