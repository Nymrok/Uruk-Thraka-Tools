-- ============================================================================
-- CORE - NOTIFICATIONS
-- ============================================================================
-- Système unifié de notifications et messages pour l'addon
-- Format standardisé : "[Uruk Thraka Tools] [Module] [Type] : [Texte]"
-- Utilise les couleurs standardisées de Constants.lua
-- ============================================================================

local addonName, addon = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

addon.Notifications = {}

-- ============================================================================
-- COULEURS POUR LES TYPES DE MESSAGES
-- ============================================================================

local MESSAGE_COLORS = {
    SUCCESS = "|cFF00FF00",  -- Vert
    ERROR = "|cFFFF0000",    -- Rouge
    WARNING = "|cFFFFFF00",  -- Jaune
    INFO = "|cFF00AAFF",     -- Bleu clair
    DEBUG = "|cFF888888"     -- Gris
}

-- ============================================================================
-- FONCTION PRINCIPALE DE FORMATAGE
-- ============================================================================

--[[
    Fonction centrale pour formater tous les messages de l'addon
    Format: "[Uruk Thraka Tools] [Module] : [Texte]"
    @param module string - Nom du module
    @param messageType string - Type de message (SUCCESS, ERROR, WARNING, INFO, DEBUG)
    @param text string - Le texte du message
]]
local function formatMessage(module, messageType, text)
    -- [Uruk Thraka Tools] en orange
    local addonPrefix = "|cFFFF8000[Uruk Thraka Tools]|r"
    
    -- [Module] coloré selon le type de message
    local typeColor = MESSAGE_COLORS[messageType] or "|cFFFFFFFF"
    local modulePrefix = typeColor .. "[" .. (module or "Général") .. "]|r"
    
    -- Texte en blanc
    local whiteText = "|cFFFFFFFF" .. text .. "|r"
    
    return addonPrefix .. " " .. modulePrefix .. " " .. whiteText
end

--[[
    Fonction interne pour envoyer le message
    @param module string - Nom du module
    @param messageType string - Type de message
    @param text string - Le texte du message
]]
local function sendMessage(module, messageType, text)
    local formattedMessage = formatMessage(module, messageType, text)
    DEFAULT_CHAT_FRAME:AddMessage(formattedMessage)
end

-- ============================================================================
-- API PUBLIQUE - AVEC MODULE
-- ============================================================================

--[[
    Affiche un message de succès avec module
    @param module string - Nom du module
    @param message string - Le message à afficher
]]
function addon.Notifications:ModuleSuccess(module, message)
    sendMessage(module, "SUCCESS", message)
end

--[[
    Affiche un message d'erreur avec module
    @param module string - Nom du module
    @param message string - Le message à afficher
]]
function addon.Notifications:ModuleError(module, message)
    sendMessage(module, "ERROR", message)
end

--[[
    Affiche un message d'avertissement avec module
    @param module string - Nom du module
    @param message string - Le message à afficher
]]
function addon.Notifications:ModuleWarning(module, message)
    sendMessage(module, "WARNING", message)
end

--[[
    Affiche un message d'information avec module
    @param module string - Nom du module
    @param message string - Le message à afficher
]]
function addon.Notifications:ModuleInfo(module, message)
    sendMessage(module, "INFO", message)
end

--[[
    Affiche un message de debug avec module (seulement si debug activé)
    @param module string - Nom du module
    @param message string - Le message à afficher
]]
function addon.Notifications:ModuleDebug(module, message)
    if UTT_Data and UTT_Data.debugMode then
        sendMessage(module, "DEBUG", message)
    end
end

-- ============================================================================
-- API DE COMPATIBILITÉ (sans module spécifié)
-- ============================================================================

--[[
    Affiche un message de succès (rétrocompatibilité)
    @param message string - Le message à afficher
]]
function addon.Notifications:Success(message)
    -- Extraire le module du message si format "[Module] texte"
    local module, text = message:match("^%[([^%]]+)%]%s*(.+)")
    if module and text then
        self:ModuleSuccess(module, text)
    else
        self:ModuleSuccess("Général", message)
    end
end

--[[
    Affiche un message d'erreur (rétrocompatibilité)
    @param message string - Le message à afficher
]]
function addon.Notifications:Error(message)
    local module, text = message:match("^%[([^%]]+)%]%s*(.+)")
    if module and text then
        self:ModuleError(module, text)
    else
        self:ModuleError("Général", message)
    end
end

--[[
    Affiche un message d'avertissement (rétrocompatibilité)
    @param message string - Le message à afficher
]]
function addon.Notifications:Warning(message)
    local module, text = message:match("^%[([^%]]+)%]%s*(.+)")
    if module and text then
        self:ModuleWarning(module, text)
    else
        self:ModuleWarning("Général", message)
    end
end

--[[
    Affiche un message d'information (rétrocompatibilité)
    @param message string - Le message à afficher
]]
function addon.Notifications:Info(message)
    local module, text = message:match("^%[([^%]]+)%]%s*(.+)")
    if module and text then
        self:ModuleInfo(module, text)
    else
        self:ModuleInfo("Général", message)
    end
end

--[[
    Affiche un message normal (rétrocompatibilité)
    @param message string - Le message à afficher
]]
function addon.Notifications:Print(message)
    local module, text = message:match("^%[([^%]]+)%]%s*(.+)")
    if module and text then
        self:ModuleInfo(module, text)
    else
        self:ModuleInfo("Général", message)
    end
end

--[[
    Affiche un message de debug (rétrocompatibilité)
    @param message string - Le message à afficher
]]
function addon.Notifications:Debug(message)
    local module, text = message:match("^%[([^%]]+)%]%s*(.+)")
    if module and text then
        self:ModuleDebug(module, text)
    else
        self:ModuleDebug("Général", message)
    end
end

-- ============================================================================
-- FONCTIONS SPÉCIALISÉES (utilisant le nouveau format)
-- ============================================================================

--[[
    Messages de résultats avec module
    @param module string - Nom du module
    @param message string - Le message à afficher
]]
function addon.Notifications:ModuleResult(module, message)
    self:ModuleSuccess(module, message)
end

--[[
    Messages "aucun résultat" avec module
    @param module string - Nom du module
    @param message string - Le message à afficher
]]
function addon.Notifications:ModuleNoResult(module, message)
    self:ModuleWarning(module, message)
end

-- ============================================================================
-- NOTIFICATIONS SPÉCIALISÉES (utilisant le nouveau format)
-- ============================================================================

--[[
    Notification pour l'ajout d'un élément
    @param itemType string - Type d'élément (ex: "Expédition", "Objet")
    @param itemName string - Nom de l'élément
    @param success boolean - Si l'ajout a réussi
]]
function addon.Notifications:ItemAdded(itemType, itemName, success)
    if success then
        self:ModuleSuccess(itemType, "Ajouté : " .. itemName)
    else
        self:ModuleError(itemType, "Impossible d'ajouter : " .. itemName)
    end
end

--[[
    Notification pour la suppression d'un élément
    @param itemType string - Type d'élément (ex: "Expédition", "Objet")
    @param itemName string - Nom de l'élément
    @param success boolean - Si la suppression a réussi
]]
function addon.Notifications:ItemRemoved(itemType, itemName, success)
    if success then
        self:ModuleSuccess(itemType, "Supprimé : " .. itemName)
    else
        self:ModuleError(itemType, "Impossible de supprimer : " .. itemName)
    end
end

--[[
    Notification pour l'activation/désactivation d'un service
    @param serviceName string - Nom du service
    @param enabled boolean - État du service
]]
function addon.Notifications:ServiceToggled(serviceName, enabled)
    if enabled then
        self:ModuleSuccess("Service", serviceName .. " activé")
    else
        self:ModuleInfo("Service", serviceName .. " désactivé")
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
