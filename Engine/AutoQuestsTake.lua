-- ============================================================================
-- Service d'acceptation automatique des quêtes
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée entre tous les fichiers
local addonName, addon = ...

-- Module d'auto-quêtes take
addon.AutoQuestsTake = {}

-- Frame pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- ============================================================================
-- FONCTIONS PRIVÉES (Mécanique interne)
-- ============================================================================

-- Fonction pour récupérer automatiquement les quêtes
local function ProcessAutoQuestsTake()
    if not addon.AutoQuestsTake:IsEnabled() then
        return
    end
    
    -- Essayer d'abord avec l'API QUEST_GREETING
    local numQuestChoices = GetNumAvailableQuests()
    
    if numQuestChoices > 0 then
        for i = 1, numQuestChoices do
            SelectAvailableQuest(i)
        end
    else
        -- Utiliser l'API C_GossipInfo + clic direct sur l'interface
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        local numCGossip = availableQuests and #availableQuests or 0
        
        if numCGossip > 0 then
            for i, questInfo in ipairs(availableQuests) do
                -- Parcourir les quêtes disponibles
            end
        end
        
        if numCGossip > 0 and GossipFrame and GossipFrame:IsVisible() then
            local questsClicked = 0
            
            -- Explorer tous les enfants du GossipFrame pour trouver les boutons
            local children = { GossipFrame:GetChildren() }
            
            for i, child in ipairs(children) do
                if child:IsVisible() and child:GetObjectType() == "Button" then
                    local text = ""
                    if child.GetText and child:GetText() then
                        text = child:GetText()
                    elseif child.titleText and child.titleText:GetText() then 
                        text = child.titleText:GetText()
                    elseif child:GetFontString() and child:GetFontString():GetText() then
                        text = child:GetFontString():GetText()
                    end
                    
                    -- Vérifier si ce bouton correspond à une quête disponible
                    if text and text ~= "" then
                        for _, questInfo in ipairs(availableQuests) do
                            if questInfo.title then
                                -- Nettoyer le texte du bouton (supprimer couleurs et (bas niveau))
                                local cleanButtonText = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub(" %(bas niveau%)", ""):trim()
                                
                                if cleanButtonText == questInfo.title or string.find(cleanButtonText, questInfo.title, 1, true) then
                                    child:Click()
                                    questsClicked = questsClicked + 1
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- FONCTIONS PUBLIQUES (API du module)
-- ============================================================================

function addon.AutoQuestsTake:IsEnabled()
    return UTT_Data and UTT_Data.autoQuestsTakeEnabled or false
end

function addon.AutoQuestsTake:Enable()
    addon:EnsureUTTData()
    UTT_Data.autoQuestsTakeEnabled = true
    eventFrame:RegisterEvent("QUEST_GREETING")
    eventFrame:RegisterEvent("GOSSIP_SHOW")
    eventFrame:RegisterEvent("QUEST_DETAIL")
end

function addon.AutoQuestsTake:Disable()
    addon:EnsureUTTData()
    UTT_Data.autoQuestsTakeEnabled = false
    eventFrame:UnregisterEvent("QUEST_GREETING")
    eventFrame:UnregisterEvent("GOSSIP_SHOW")
    eventFrame:UnregisterEvent("QUEST_DETAIL")
end

-- ============================================================================
-- INITIALISATION ET ÉVÉNEMENTS
-- ============================================================================

function addon.AutoQuestsTake:Init()
    addon:EnsureUTTData()
    if UTT_Data.autoQuestsTakeEnabled == nil then
        UTT_Data.autoQuestsTakeEnabled = false
    end
    
    if UTT_Data.autoQuestsTakeEnabled then
        eventFrame:RegisterEvent("QUEST_GREETING")
        eventFrame:RegisterEvent("GOSSIP_SHOW")
        eventFrame:RegisterEvent("QUEST_DETAIL")
    end
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if not addon.AutoQuestsTake:IsEnabled() then
            return
        end
        
        if event == "QUEST_GREETING" or event == "GOSSIP_SHOW" then
            -- Délai pour laisser l'interface se charger
            C_Timer.After(0.2, function()
                ProcessAutoQuestsTake()
            end)
        elseif event == "QUEST_DETAIL" then
            AcceptQuest()
        end
    end)
end
