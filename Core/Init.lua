-- ============================================================================
-- Module principal d'initialisation de l'addon Uruk Thraka Tools
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée
local addonName, addon = ...
UTT = addon

-- Initialisation des modules UI essentiels
addon.ButtonTemplates = addon.ButtonTemplates or {}

-- Configurations globales
addon.version = C_AddOns.GetAddOnMetadata(addonName, "Version")

-- Couleurs pour les messages (DEPRECATED - utiliser addon.Colors)
addon.colors = {
    prefix = addon.Colors:GetHex("ADDON_PREFIX"),
    error = addon.Colors:GetHex("ERROR"),
    warning = addon.Colors:GetHex("WARNING"),
    success = addon.Colors:GetHex("SUCCESS")
}

addon.ADDON_PREFIX = addon.Colors:GetHex("ADDON_PREFIX") .. "[Uruk Thraka Tools]|r "

-- Fonction pour afficher les messages (DEPRECATED - utiliser addon.Notifications)
function addon:Print(msg)
    addon.Notifications:Print(msg)
end

-- Système de log dans SavedVariables
function addon:Log(msg)
    self:EnsureUTTData()
    
    -- Initialiser la table de log si elle n'existe pas
    if not UTT_Data.logs then
        UTT_Data.logs = {}
    end
    
    -- Créer l'entrée de log avec timestamp
    local timeStr = date("%H:%M:%S")
    local logEntry = string.format("[%s] %s", timeStr, msg)
    
    -- Ajouter la nouvelle entrée
    table.insert(UTT_Data.logs, logEntry)
    
    -- Limiter à 200 entrées (supprimer les plus anciennes)
    while #UTT_Data.logs > 200 do
        table.remove(UTT_Data.logs, 1)
    end
end

-- Fonction utilitaire pour s'assurer que UTT_Data existe
function addon:EnsureUTTData()
    if not UTT_Data then
        UTT_Data = {
            enabled = true,
        }
    end
end

-- Frame principale pour la gestion des événements
addon.frame = CreateFrame("Frame")

-- Fonction d'initialisation
function addon:OnLoad()
    -- Initialisation des variables sauvegardées
    if not UTT_Data then
        UTT_Data = {
            -- Structure par défaut des données sauvegardées
            enabled = true,
            -- Ajoutez d'autres variables par défaut ici
        }
        self:Print("Initialisation des données par défaut.")
    end

    -- Enregistrement de la commande slash
    SLASH_UTT1 = "/utt"
    SlashCmdList["UTT"] = function(msg)
        addon:HandleSlashCommand(msg)
    end

-- Commandes pour ExpeditionsService
SLASH_UTTEXPEDITIONS1 = "/uttexpeditions"
SlashCmdList["UTTEXPEDITIONS"] = function(msg)
    if msg == "enable" then
        addon.ExpeditionsService:Enable()
    elseif msg == "disable" then
        addon.ExpeditionsService:Disable()
    elseif msg == "status" then
        local status = addon.ExpeditionsService:IsEnabled() and "activé" or "désactivé"
        local count = addon.ExpeditionsService:GetAvailableCount()
        print("[UTT] Service Expéditions : " .. status .. " (" .. count .. " disponibles)")
    else
        print("[UTT] Commandes : /uttexpeditions enable|disable|status")
    end
end

-- ============================================================================
-- FONCTION ADDONCOMPARTMENT
-- ============================================================================

--[[
    Fonction pour l'AddonCompartment (icône Blizzard)
    @param addonName string - Nom de l'addon
    @param leftClick boolean - true si clic gauche
]]
function UTT_AC(addonName, leftClick)
    if leftClick then
        if addon.UI and addon.UI.mainFrame then
            if addon.UI.mainFrame:IsShown() then
                addon.UI:Hide()
            else
                addon.UI:Show()
            end
        end
    end
end    -- Nettoyage AGRESSIF de toutes les anciennes clés à chaque chargement
    if UTT_Data then
        -- Liste complète des clés à supprimer
        local keysToRemove = {
            "scanBagsEnabled", "autoOpenItems", "inventorySnapshot", "debugLog",
            "scanButtonsEnabled", "acceptLowLevelQuests", "completeLowLevelQuests", "scanQuestsEnabled",
            "lastScanTime", "autoQuestsReturnTrivialEnabled", "autoSellEnabled", "betterTooltipEnabled",
            "autoQuestsAcceptEnabled", "autoQuestsReturnDailyEnabled", "autoQuestEnabled",
            "autoCompleteQuestsEnabled", "autoQuestsAcceptWeeklyEnabled", "autoQuestsAcceptRepeatableEnabled",
            "acceptNormalQuests", "autoQuestsAcceptTrivialEnabled", "autoQuestsReturnWeeklyEnabled",
            "autoQuestsAcceptNormalEnabled", "completeNormalQuests", "autoAcceptQuestsEnabled",
            "completeRepeatableQuests", "autoQuestsAcceptDefaultEnabled",
            "autoQuestsAcceptDailyEnabled", "autoQuestsReturnDefaultEnabled", "ScanBagsEnabled",
            "acceptRepeatableQuests", "autoQuestsAcceptLowLevelEnabled", "currentInventory"
        }
        
        -- Supprimer toutes les clés obsolètes
        local cleanedCount = 0
        for _, key in ipairs(keysToRemove) do
            if UTT_Data[key] ~= nil then
                UTT_Data[key] = nil
                cleanedCount = cleanedCount + 1
            end
        end
        
        if cleanedCount > 0 then
            addon:Print("Nettoyage automatique : " .. cleanedCount .. " clés obsolètes supprimées.")
        end
    end

    -- Initialisation des modules
    if self.AutoQuestsTake then
        self.AutoQuestsTake:Init()
    end
    if self.AutoQuestsReturn then
        self.AutoQuestsReturn:Init()
    end
    if self.AutoSellGrey then
        self.AutoSellGrey:Init()
    end
    if self.FastLoot then
        self.FastLoot:Init()
    end
    if self.AutoRepair then
        self.AutoRepair:Init()
    end
    if self.InventoryService then
        self.InventoryService:Init()
    end

    -- Initialisation de l'interface
    self.UI:Init()
    
    -- Vérifier que le displayer est bien enregistré
    if not self.Displayer then
        self.Displayer = {}
        self:Print("ATTENTION : Table Displayer initialisée vide !")
    end

    -- Initialisation du service Expéditions
    if self.ExpeditionsService then
        self.ExpeditionsService:Init()
    end
    
    -- Initialisation de l'indicateur d'expéditions
    if self.ExpeditionsIndicator then
        self.ExpeditionsIndicator:Init()
    end
    
    -- Initialisation du bouton d'ouverture
    if self.OpenButton then
        self.OpenButton:Init()
    end
end

-- Gestion des événements
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        addon:OnLoad()
    end
end

addon.frame:RegisterEvent("ADDON_LOADED")
addon.frame:SetScript("OnEvent", OnEvent)
