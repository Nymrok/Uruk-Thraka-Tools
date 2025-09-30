-- ============================================================================
-- Page d'accueil avec informations sur l'addon et instructions
-- ============================================================================

-- Récupération du nom de l'addon et de la table partagée
local addonName, addon = ...
addon.Displayer = addon.Displayer or {}
addon.Displayer.Home = {}
addon.Displayer.Home.header = "Bienvenue"

function addon.Displayer.Home:CreateContent(displayFrame)
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "Inconnue"
    local author = C_AddOns.GetAddOnMetadata(addonName, "Author") or "Inconnu"
    
    local nameText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", 20, -20)
    nameText:SetText("|cffffd700Uruk Thraka Tools|r ")
    nameText:SetTextColor(1, 1, 1, 1)
    nameText:SetJustifyH("LEFT")
    
    local versionText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("TOPLEFT", nameText, "TOPLEFT", 0, -26)
    versionText:SetText("|cffffd700Version :|r " .. version)
    versionText:SetTextColor(1, 1, 1, 1)
    versionText:SetJustifyH("LEFT")

    local authorText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    authorText:SetPoint("TOPLEFT", versionText, "TOPLEFT", 0, -20)
    authorText:SetText("|cffffd700Auteur :|r " .. author)
    authorText:SetTextColor(1, 1, 1, 1)
    authorText:SetJustifyH("LEFT")

    local contactText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contactText:SetPoint("TOPLEFT", authorText, "TOPLEFT", 0, -20)
    contactText:SetText("|cffffd700Contact : |r " .. "gaming@nymrok.fr")
    contactText:SetTextColor(1, 1, 1, 1)
    contactText:SetJustifyH("LEFT")

    local whatsNext = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    whatsNext:SetPoint("TOPLEFT", contactText, "TOPLEFT", 0, -35)
    whatsNext:SetText("|cffffd700Fonctionnalités en cours de développement :|r\n\n• Ajout de notes personnalisées à chaque expédition surveillée\n\n• Shopping List personnalisable pour se souvenir de votre équipement Best-In-Slot")
    whatsNext:SetTextColor(1, 1, 1, 1)
    whatsNext:SetJustifyH("LEFT")

    local knownIssues = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    knownIssues:SetPoint("TOPLEFT", whatsNext, "BOTTOMLEFT", 0, -30)
    knownIssues:SetText("|cffffd700Bugs connus :|r\n\n• Aucun")
    knownIssues:SetTextColor(1, 1, 1, 1)
    knownIssues:SetJustifyH("LEFT")

    if addon.Display and addon.Display.UpdateContentHeight then
        C_Timer.After(0.1, function()
            addon.Display:UpdateContentHeight()
        end)
    end
end
