-- ============================================================================
-- Interface utilisateur pour la gestion automatique des quêtes
-- ============================================================================
local addonName, addon = ...
addon.Displayer = addon.Displayer or {}
addon.Displayer.Quests = {}
addon.Displayer.Quests.header = "Quêtes"

function addon.Displayer.Quests:CreateContent(displayFrame)
    local Quests_Checkbox = CreateFrame("CheckButton", nil, displayFrame, "UICheckButtonTemplate")
    Quests_Checkbox:SetSize(24, 24)
    Quests_Checkbox:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", 20, -20)
    Quests_Checkbox:SetChecked(addon.AutoQuestsTake and addon.AutoQuestsTake:IsEnabled() or false)

    local Quests_Description = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Quests_Description:SetPoint("LEFT", Quests_Checkbox, "RIGHT", 5, 0)
    Quests_Description:SetText("Récupérer automatiquement les quêtes disponibles")
    Quests_Description:SetTextColor(1, 1, 1, 1)

    Quests_Checkbox:SetScript("OnClick", function(self)
        if not addon.AutoQuestsTake then return end
        if self:GetChecked() then
            addon.AutoQuestsTake:Enable()
        else
            addon.AutoQuestsTake:Disable()
        end
    end)
    
    local QuestsReturn_Checkbox = CreateFrame("CheckButton", nil, displayFrame, "UICheckButtonTemplate")
    QuestsReturn_Checkbox:SetSize(24, 24)
    QuestsReturn_Checkbox:SetPoint("TOPLEFT", Quests_Checkbox, "BOTTOMLEFT", 0, -6)
    QuestsReturn_Checkbox:SetChecked(addon.AutoQuestsReturn and addon.AutoQuestsReturn:IsEnabled() or false)

    local QuestsReturn_Description = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    QuestsReturn_Description:SetPoint("LEFT", QuestsReturn_Checkbox, "RIGHT", 5, 0)
    QuestsReturn_Description:SetText("Rendre automatiquement les quêtes terminées")
    QuestsReturn_Description:SetTextColor(1, 1, 1, 1)

    QuestsReturn_Checkbox:SetScript("OnClick", function(self)
        if not addon.AutoQuestsReturn then return end
        if self:GetChecked() then
            addon.AutoQuestsReturn:Enable()
        else
            addon.AutoQuestsReturn:Disable()
        end
    end)
    
    if addon.Display and addon.Display.UpdateContentHeight then
        C_Timer.After(0.1, function()
            addon.Display:UpdateContentHeight()
        end)
    end
end
