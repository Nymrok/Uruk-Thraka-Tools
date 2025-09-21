-- ============================================================================
-- Interface utilisateur pour la gestion de l'équipement et réparations
-- ============================================================================
local addonName, addon = ...
addon.Displayer = addon.Displayer or {}
addon.Displayer.Gear = {}
addon.Displayer.Gear.header = "Équipement"

function addon.Displayer.Gear:CreateContent(displayFrame)
    local AutoRepair_Checkbox = CreateFrame("CheckButton", nil, displayFrame, "UICheckButtonTemplate")
    AutoRepair_Checkbox:SetSize(24, 24)
    AutoRepair_Checkbox:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", 20, -20)
    AutoRepair_Checkbox:SetChecked(addon.AutoRepair and addon.AutoRepair:IsEnabled() or false)
    
    local AutoRepair_Description = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    AutoRepair_Description:SetPoint("LEFT", AutoRepair_Checkbox, "RIGHT", 5, 0)
    AutoRepair_Description:SetText("Réparer automatiquement l'équipement")
    AutoRepair_Description:SetTextColor(1, 1, 1, 1)
    
    AutoRepair_Checkbox:SetScript("OnClick", function(self)
        if not addon.AutoRepair then return end
        if self:GetChecked() then
            addon.AutoRepair:Enable()
        else
            addon.AutoRepair:Disable()
        end
    end)
    
    if addon.Display and addon.Display.UpdateContentHeight then
        C_Timer.After(0.1, function()
            addon.Display:UpdateContentHeight()
        end)
    end
end
