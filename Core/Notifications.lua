-- ============================================================================
-- CORE - NOTIFICATIONS
-- ============================================================================
-- Système unifié de notifications et messages pour l'addon
-- Utilise les couleurs standardisées de Constants.lua
-- ============================================================================

local addonName, addon = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

addon.Notifications = {}

-- ============================================================================
-- SYSTÈME DE NOTIFICATIONS
-- ============================================================================

--[[
    Affiche un message de succès
    @param message string - Le message à afficher
]]
function addon.Notifications:Success(message)
    local prefix = addon.Colors:GetHex("ADDON_PREFIX") .. "[Uruk Thraka Tools]|r "
    local coloredMessage = addon.Colors:GetHex("SUCCESS") .. message .. "|r"
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. coloredMessage)
end

--[[
    Affiche un message d'erreur
    @param message string - Le message à afficher
]]
function addon.Notifications:Error(message)
    local prefix = addon.Colors:GetHex("ADDON_PREFIX") .. "[Uruk Thraka Tools]|r "
    local coloredMessage = addon.Colors:GetHex("ERROR") .. "Erreur : " .. message .. "|r"
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. coloredMessage)
end

--[[
    Affiche un message d'avertissement
    @param message string - Le message à afficher
]]
function addon.Notifications:Warning(message)
    local prefix = addon.Colors:GetHex("ADDON_PREFIX") .. "[Uruk Thraka Tools]|r "
    local coloredMessage = addon.Colors:GetHex("WARNING") .. "Attention : " .. message .. "|r"
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. coloredMessage)
end

--[[
    Affiche un message d'information
    @param message string - Le message à afficher
]]
function addon.Notifications:Info(message)
    local prefix = addon.Colors:GetHex("ADDON_PREFIX") .. "[Uruk Thraka Tools]|r "
    local coloredMessage = addon.Colors:GetHex("INFO") .. message .. "|r"
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. coloredMessage)
end

--[[
    Affiche un message normal (sans couleur spéciale)
    @param message string - Le message à afficher
]]
function addon.Notifications:Print(message)
    local prefix = addon.Colors:GetHex("ADDON_PREFIX") .. "[Uruk Thraka Tools]|r "
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. message)
end

--[[
    Affiche un message de debug (seulement si le debug est activé)
    @param message string - Le message à afficher
]]
function addon.Notifications:Debug(message)
    -- TODO: Ajouter une variable de configuration pour le debug
    if UTT_Data and UTT_Data.debugMode then
        local prefix = addon.Colors:GetHex("ADDON_PREFIX") .. "[UTT Debug]|r "
        local coloredMessage = addon.Colors:GetHex("MUTED") .. message .. "|r"
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. coloredMessage)
    end
end

-- ============================================================================
-- NOTIFICATIONS SPÉCIALISÉES
-- ============================================================================

--[[
    Notification pour l'ajout d'un élément
    @param itemType string - Type d'élément (ex: "expédition", "objet")
    @param itemName string - Nom de l'élément
    @param success boolean - Si l'ajout a réussi
]]
function addon.Notifications:ItemAdded(itemType, itemName, success)
    if success then
        self:Success(itemType:gsub("^%l", string.upper) .. " ajoutée : " .. itemName)
    else
        self:Error("Impossible d'ajouter " .. itemType .. " : " .. itemName)
    end
end

--[[
    Notification pour la suppression d'un élément
    @param itemType string - Type d'élément (ex: "expédition", "objet")
    @param itemName string - Nom de l'élément
    @param success boolean - Si la suppression a réussi
]]
function addon.Notifications:ItemRemoved(itemType, itemName, success)
    if success then
        self:Success(itemType:gsub("^%l", string.upper) .. " supprimée : " .. itemName)
    else
        self:Error("Impossible de supprimer " .. itemType .. " : " .. itemName)
    end
end

--[[
    Notification pour l'activation/désactivation d'un service
    @param serviceName string - Nom du service
    @param enabled boolean - État du service
]]
function addon.Notifications:ServiceToggled(serviceName, enabled)
    if enabled then
        self:Success("Service " .. serviceName .. " activé")
    else
        self:Info("Service " .. serviceName .. " désactivé")
    end
end

--[[
    Notification pour les expéditions disponibles
    @param expeditionName string - Nom de l'expédition
    @param available boolean - Si l'expédition est disponible
]]
function addon.Notifications:ExpeditionStatus(expeditionName, available)
    if available then
        self:Success("Expédition disponible : " .. expeditionName)
    else
        self:Info("Expédition terminée : " .. expeditionName)
    end
end

-- ============================================================================
-- RÉTROCOMPATIBILITÉ
-- ============================================================================

-- Maintenir la fonction Print existante pour compatibilité
if not addon.Print then
    function addon:Print(msg)
        addon.Notifications:Print(msg)
    end
end
