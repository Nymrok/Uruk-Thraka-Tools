-- ============================================================================
-- Service de rendu automatique des quêtes complétées
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée entre tous les fichiers
local addonName, addon = ...

-- Module d'auto-quêtes return
addon.AutoQuestsReturn = {}

-- Frame pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- ============================================================================
-- FONCTIONS PRIVÉES (Mécanique interne)
-- ============================================================================

-- Fonction pour rendre automatiquement les quêtes terminées
local function ProcessAutoQuestsReturn()
    if not addon.AutoQuestsReturn:IsEnabled() then
        return
    end
    
    -- API classique (QUEST_GREETING)
    local numActive = GetNumActiveQuests()
    if numActive and numActive > 0 then
        for i = 1, numActive do
            local title, isComplete = GetActiveTitle(i)
            if title and isComplete then
                SelectActiveQuest(i)
                return
            end
        end
    end
    
    -- API moderne (GOSSIP_SHOW)
    local success, activeQuests = pcall(C_GossipInfo.GetActiveQuests)
    if success and activeQuests then
        for _, questInfo in ipairs(activeQuests) do
            if questInfo.title and questInfo.isComplete and questInfo.questID then
                pcall(C_GossipInfo.SelectActiveQuest, questInfo.questID)
                return
            end
        end
    end
end

-- ============================================================================
-- FONCTIONS PUBLIQUES (API du module)
-- ============================================================================

function addon.AutoQuestsReturn:IsEnabled()
    return UTT_Data and UTT_Data.autoQuestsReturnEnabled or false
end

function addon.AutoQuestsReturn:Enable()
    addon:EnsureUTTData()
    UTT_Data.autoQuestsReturnEnabled = true
    eventFrame:RegisterEvent("QUEST_GREETING")
    eventFrame:RegisterEvent("GOSSIP_SHOW")
    eventFrame:RegisterEvent("QUEST_PROGRESS")
    eventFrame:RegisterEvent("QUEST_COMPLETE")
    eventFrame:RegisterEvent("QUEST_DETAIL")
end

function addon.AutoQuestsReturn:Disable()
    addon:EnsureUTTData()
    UTT_Data.autoQuestsReturnEnabled = false
    eventFrame:UnregisterEvent("QUEST_GREETING")
    eventFrame:UnregisterEvent("GOSSIP_SHOW")
    eventFrame:UnregisterEvent("QUEST_PROGRESS")
    eventFrame:UnregisterEvent("QUEST_COMPLETE")
    eventFrame:UnregisterEvent("QUEST_DETAIL")
end

-- ============================================================================
-- INITIALISATION ET ÉVÉNEMENTS
-- ============================================================================

function addon.AutoQuestsReturn:Init()
    addon:EnsureUTTData()
    if UTT_Data.autoQuestsReturnEnabled == nil then
        UTT_Data.autoQuestsReturnEnabled = false
    end
    
    if UTT_Data.autoQuestsReturnEnabled then
        eventFrame:RegisterEvent("QUEST_GREETING")
        eventFrame:RegisterEvent("GOSSIP_SHOW")
        eventFrame:RegisterEvent("QUEST_PROGRESS")
        eventFrame:RegisterEvent("QUEST_COMPLETE")
        eventFrame:RegisterEvent("QUEST_DETAIL")
    end
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if not addon.AutoQuestsReturn:IsEnabled() then
            return
        end
        
        if event == "QUEST_GREETING" or event == "GOSSIP_SHOW" then
            ProcessAutoQuestsReturn()
        elseif event == "QUEST_PROGRESS" then
            if IsQuestCompletable() then
                CompleteQuest()
            end
        elseif event == "QUEST_COMPLETE" then
            local numRewardChoices = GetNumQuestChoices()
            if numRewardChoices <= 1 then
                GetQuestReward(numRewardChoices)
            end
        elseif event == "QUEST_DETAIL" then
            AcceptQuest()
        end
    end)
end
