-- ============================================================================
-- Composant réutilisable pour l'affichage et gestion des listes
-- ============================================================================

local addonName, addon = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

addon.ListComponent = {}

-- ============================================================================
-- CONFIGURATION PAR DÉFAUT
-- ============================================================================

local DEFAULT_CONFIG = {
    -- Messages
    emptyMessage = "Aucun élément configuré",
    disabledMessage = "Fonctionnalité désactivée",
    
    -- Dimensions
    rowHeight = 36,
    rowSpacing = 41, -- 36 + 5px d'espacement entre les lignes
    buttonSize = 32, -- Réduit pour rentrer dans la ligne
    iconSize = 32,
    
    -- Espacements
    marginLeft = 5, -- 5px de marge entre la bordure jaune et le contenu
    marginRight = 5, -- 5px de marge entre la bordure jaune et le contenu
    
    -- Couleurs
    normalColor = addon.Colors.NORMAL,
    disabledColor = addon.Colors.DISABLED,
    mutedColor = addon.Colors.MUTED,
}

-- ============================================================================
-- FONCTIONS UTILITAIRES
-- ============================================================================

--[[
    Nettoie tous les éléments d'une liste
    @param itemsList table - La liste à nettoyer
]]
local function cleanupList(itemsList)
    for _, item in pairs(itemsList) do
        if item and item.Hide then
            item:Hide()
            item:SetParent(nil)
        end
    end
    wipe(itemsList)
end

--[[
    Crée un message d'état (vide, désactivé, etc.)
    @param container Frame - Le conteneur parent
    @param message string - Le message à afficher
    @param color table - La couleur du texte
    @return FontString - L'élément créé
]]
local function createStatusMessage(container, message, color)
    local statusText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOP", container, "TOP", 0, -10)
    statusText:SetText(message)
    statusText:SetTextColor(color.r, color.g, color.b, color.a)
    return statusText
end

-- ============================================================================
-- API PUBLIQUE
-- ============================================================================

--[[
    Crée une nouvelle liste gérée
    @param parent Frame - Le frame parent
    @param config table - Configuration de la liste
    @return table - L'objet liste
]]
function addon.ListComponent:Create(parent, config)
    -- Fusion avec la configuration par défaut
    config = config or {}
    for key, value in pairs(DEFAULT_CONFIG) do
        if config[key] == nil then
            config[key] = value
        end
    end
    
    -- Créer le conteneur principal qui prend TOUTE la place du parent
    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints(parent)
    
    -- Créer la CustomScrollFrameSD avec support molette et boutons visuels
    -- Obtenir les dimensions du parent ou utiliser des valeurs par défaut
    local containerWidth = parent:GetWidth() or 400
    local containerHeight = parent:GetHeight() or 300
    local scrollFrameSD = addon.CustomScrollFrameSD:Create(container, containerWidth, containerHeight)
    scrollFrameSD.mainFrame:SetAllPoints(container)
    
    -- Le scrollChild est maintenant fourni par la CustomScrollFrameSD
    local scrollChild = scrollFrameSD.scrollChild
    
    -- État interne
    local itemsList = {}
    local listObject = {
        container = container,
        scrollFrameSD = scrollFrameSD,
        scrollFrame = scrollFrameSD, -- Le scrollFrame est directement retourné par CustomScrollFrameSD
        scrollChild = scrollChild,
        itemsList = itemsList,
        config = config
    }
    
    --[[
        Met à jour la liste avec les nouvelles données
        @param data table - Les données à afficher
        @param isEnabled boolean - Si la fonctionnalité est activée
    ]]
    function listObject:Update(data, isEnabled)
        -- Nettoyer la liste existante
        cleanupList(self.itemsList)
        
        if not isEnabled then
            -- Fonctionnalité désactivée
            local disabledText = createStatusMessage(
                self.scrollChild, 
                self.config.disabledMessage, 
                self.config.disabledColor
            )
            table.insert(self.itemsList, disabledText)
            self.scrollChild:SetHeight(30)
            self.scrollChild:SetWidth(self.container:GetWidth())
            return
        end
        
        if not data or not next(data) then
            -- Aucun élément
            local emptyText = createStatusMessage(
                self.scrollChild, 
                self.config.emptyMessage, 
                self.config.mutedColor
            )
            table.insert(self.itemsList, emptyText)
            self.scrollChild:SetHeight(30)
            self.scrollChild:SetWidth(self.container:GetWidth())
            return
        end
        
        -- Créer les éléments avec tri alphabétique
        local yOffset = 0
        
        -- Convertir les données en tableau trié par nom
        local sortedItems = {}
        for id, itemData in pairs(data) do
            table.insert(sortedItems, {
                id = id,
                data = itemData,
                name = itemData.name or itemData.displayName or tostring(id) -- Nom pour le tri
            })
        end
        
        -- Trier par ordre alphabétique (insensible à la casse)
        table.sort(sortedItems, function(a, b)
            local nameA = string.lower(a.name)
            local nameB = string.lower(b.name)
            return nameA < nameB
        end)
        
        -- Créer les lignes dans l'ordre trié
        for _, item in ipairs(sortedItems) do
            local row = self:CreateRow(item.id, item.data, yOffset)
            table.insert(self.itemsList, row)
            yOffset = yOffset - self.config.rowSpacing
        end
        
        -- Ajuster les dimensions du contenu scrollable
        local totalHeight = math.abs(yOffset) + 10
        self.scrollChild:SetHeight(totalHeight)
        self.scrollChild:SetWidth(self.container:GetWidth())
        
        -- Remettre le scroll en haut lors du refresh
        self.scrollFrame:SetVerticalScroll(0)
    end
    
    --[[
        Crée une ligne d'élément
        @param id any - L'identifiant de l'élément
        @param data table - Les données de l'élément
        @param yOffset number - Le décalage vertical
        @return Frame - La ligne créée
    ]]
    function listObject:CreateRow(id, data, yOffset)
        local row = CreateFrame("Frame", nil, self.scrollChild) -- Utiliser scrollChild au lieu de container
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", self.config.marginLeft, yOffset - self.config.marginLeft)
        row:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", -self.config.marginRight, yOffset - self.config.marginLeft)
        row:SetHeight(self.config.rowHeight)
        
        -- Bouton de suppression (à gauche)
                local deleteButton = addon.ButtonTemplates.CreateHD_Btn_Delete(row)
        deleteButton:SetPoint("LEFT", row, "LEFT", 2, 0) -- 2px de marge depuis le bord gauche
        
        deleteButton:SetScript("OnClick", function()
            if self.config.onDelete then
                self.config.onDelete(id, data)
            end
        end)
        
        -- Appeler la fonction de rendu personnalisée
        if self.config.renderRow then
            self.config.renderRow(row, deleteButton, id, data, self.config)
        end
        
        return row
    end
    
    --[[
        Définit la position du conteneur
        @param point string - Point d'ancrage
        @param relativeTo Frame - Frame de référence
        @param relativePoint string - Point de référence
        @param x number - Décalage X
        @param y number - Décalage Y
    ]]
    function listObject:SetPoint(point, relativeTo, relativePoint, x, y)
        self.container:SetPoint(point, relativeTo, relativePoint, x, y)
    end
    
    --[[
        Définit la largeur du conteneur
        @param point1 string - Premier point d'ancrage
        @param relativeTo1 Frame - Première référence
        @param relativePoint1 string - Premier point de référence
        @param x1 number - Premier décalage X
        @param point2 string - Deuxième point d'ancrage
        @param relativeTo2 Frame - Deuxième référence
        @param relativePoint2 string - Deuxième point de référence
        @param x2 number - Deuxième décalage X
    ]]
    function listObject:SetWidth(point1, relativeTo1, relativePoint1, x1, point2, relativeTo2, relativePoint2, x2)
        self.container:SetPoint(point1, relativeTo1, relativePoint1, x1, 0)
        self.container:SetPoint(point2, relativeTo2, relativePoint2, x2, 0)
    end
    
    return listObject
end

-- ============================================================================
-- FONCTIONS DE RENDU PRÉDÉFINIES
-- ============================================================================

--[[
    Fonction de rendu pour les expéditions
    @param row Frame - La ligne
    @param deleteButton Button - Le bouton de suppression
    @param questID number - L'ID de la quête
    @param data table - Les données de l'expédition
    @param config table - La configuration
]]
function addon.ListComponent.RenderExpedition(row, deleteButton, questID, data, config)
    local rowHeight = config.rowHeight or 60
    
    -- Ligne A : Boutons (centrés verticalement dans la row)
    -- Bouton suppression (ligne A) - déjà positionné par le système
    
    -- ViewButtonHD remplace l'icône d'expédition (ligne A, espacé de 5px du bouton de suppression)
    local viewButton = addon.ButtonTemplates.CreateHD_Btn_VisibilityOn(row)
    viewButton:SetPoint("LEFT", deleteButton, "RIGHT", 0, 0)
    
    -- Vérifier si l'expédition est disponible
    local isAvailable = addon.ExpeditionsService and addon.ExpeditionsService:IsAvailable(questID)
    
    if isAvailable then
        -- Expédition disponible : bouton actif avec fonctionnalité complète
        viewButton:SetEnabled(true)
        
        -- Fonctionnalité d'ouverture de carte au clic
        viewButton:SetScript("OnClick", function()
            -- Code d'ouverture de carte existant...
            if questID then
                -- Récupérer les informations de localisation de l'expédition
                local questInfo = C_TaskQuest.GetQuestInfoByQuestID(questID)
                local questName = data.name or ("ID " .. questID)
                
                if questInfo and questInfo.mapID then
                    -- Ouvrir ou naviguer vers la carte appropriée SANS déplacer la vue
                    if WorldMapFrame and WorldMapFrame:IsShown() then
                        -- Si la carte est déjà ouverte, naviguer vers la zone DE L'EXPÉDITION
                        WorldMapFrame:SetMapID(questInfo.mapID)
                        print("[UTT] Carte ouverte pour " .. questName .. " (Zone: " .. questInfo.mapID .. ")")
                    else
                        -- Ouvrir la carte puis naviguer vers la zone DE L'EXPÉDITION
                        ToggleWorldMap()
                        print("[UTT] Ouverture de la carte pour " .. questName .. " (Zone: " .. questInfo.mapID .. ")")
                        -- Délai court pour l'ouverture de l'interface
                        C_Timer.After(0.1, function()
                            if WorldMapFrame then
                                WorldMapFrame:SetMapID(questInfo.mapID)
                            end
                        end)
                    end
                    -- SUPPRIMÉ : Le centrage automatique qui déplace la vue
                else
                    -- Chercher dans toutes les zones connues pour trouver cette expédition
                    local foundMapID = nil
                    
                    -- D'abord essayer les zones TWW prioritaires
                    local searchZones = {2248, 2339, 2214, 2215, 2255, 2256, 2346}
                    
                    for _, mapID in ipairs(searchZones) do
                        local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
                        if quests then
                            for _, quest in ipairs(quests) do
                                if quest.questID == questID then
                                    foundMapID = quest.mapID or mapID
                                    break
                                end
                            end
                            if foundMapID then break end
                        end
                    end
                    
                    -- Si pas trouvée, essayer TOUTES les zones de notre liste de scan
                    if not foundMapID then
                        local allScanZones = {
                            -- The War Within (complètes)
                            2248, 2339, 2214, 2215, 2255, 2256, 2213, 2274, 2216, 2217, 
                            2267, 2269, 2270, 2271, 2272, 2273, 2275, 2276, 2277, 2278, 
                            2279, 2280, 2346,
                            -- Dragonflight  
                            2022, 2023, 2024, 2025, 2112, 2151,
                            -- Shadowlands
                            1533, 1525, 1536, 1565, 1970, 1961,
                            -- Battle for Azeroth
                            875, 876, 862, 863, 864, 896, 942,
                            -- Legion + Argus (AJOUTÉ : zones manquantes)
                            630, 641, 650, 634, 680, 646, 790, 882,
                            830, 885, 994 -- Mac'Aree, Étendues Antoréennes, Argus (zones d'Argus manquantes)
                        }
                        
                        for _, mapID in ipairs(allScanZones) do
                            local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
                            if quests then
                                for _, quest in ipairs(quests) do
                                    if quest.questID == questID then
                                        foundMapID = quest.mapID or mapID
                                        break
                                    end
                                end
                                if foundMapID then break end
                            end
                        end
                    end
                    
                    -- Si toujours pas trouvée, essayer la zone actuelle du joueur
                    if not foundMapID then
                        local currentMapID = C_Map.GetBestMapForUnit("player")
                        if currentMapID then
                            local quests = C_TaskQuest.GetQuestsForPlayerByMapID(currentMapID)
                            if quests then
                                for _, quest in ipairs(quests) do
                                    if quest.questID == questID then
                                        foundMapID = quest.mapID or currentMapID
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Si on a trouvé une zone, ouvrir la carte
                    if foundMapID then
                        if WorldMapFrame and WorldMapFrame:IsShown() then
                            WorldMapFrame:SetMapID(foundMapID)
                            print("[UTT] Carte trouvée via recherche étendue pour " .. questName .. " (Zone: " .. foundMapID .. ")")
                        else
                            ToggleWorldMap()
                            print("[UTT] Ouverture de la carte via recherche étendue pour " .. questName .. " (Zone: " .. foundMapID .. ")")
                            C_Timer.After(0.1, function()
                                if WorldMapFrame then
                                    WorldMapFrame:SetMapID(foundMapID)
                                end
                            end)
                        end
                    else
                        -- Dernière tentative : utiliser les APIs WoW pour deviner la zone
                        local fallbackMapID = nil
                        
                        -- Méthode 1: Essayer de récupérer des infos via d'autres APIs
                        if C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID) then
                            -- C'est une quête active, essayer d'obtenir sa zone
                            local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
                            if logIndex then
                                local info = C_QuestLog.GetInfo(logIndex)
                                if info and info.campaignID then
                                    -- Essayer de deviner la zone via la campagne
                                    fallbackMapID = C_Map.GetBestMapForUnit("player") -- Au moins la zone du joueur
                                end
                            end
                        end
                        
                        -- Méthode 2: Si c'est une World Quest, elle devrait avoir une zone associée
                        if not fallbackMapID and C_QuestLog.IsWorldQuest(questID) then
                            -- Pour les World Quests, essayer toutes les zones récentes
                            local recentZones = {2346, 2248, 2215, 2214, 2255} -- Zones TWW les plus communes
                            for _, testMapID in ipairs(recentZones) do
                                local mapQuests = C_TaskQuest.GetQuestsForPlayerByMapID(testMapID)
                                if mapQuests then
                                    for _, quest in ipairs(mapQuests) do
                                        if quest.questID == questID then
                                            fallbackMapID = testMapID
                                            break
                                        end
                                    end
                                    if fallbackMapID then break end
                                end
                            end
                        end
                        
                        -- Si on a trouvé quelque chose, l'utiliser
                        if fallbackMapID then
                            if WorldMapFrame and WorldMapFrame:IsShown() then
                                WorldMapFrame:SetMapID(fallbackMapID)
                                print("[UTT] Carte trouvée via méthode de fallback pour " .. questName .. " (Zone: " .. fallbackMapID .. ")")
                            else
                                ToggleWorldMap()
                                print("[UTT] Ouverture de la carte via méthode de fallback pour " .. questName .. " (Zone: " .. fallbackMapID .. ")")
                                C_Timer.After(0.1, function()
                                    if WorldMapFrame then
                                        WorldMapFrame:SetMapID(fallbackMapID)
                                    end
                                end)
                            end
                        else
                            -- Vraiment dernière option : ouvrir la carte du joueur
                            print("[UTT] Localisation introuvable pour " .. questName .. " - Ouverture de la carte générale")
                            if not WorldMapFrame:IsShown() then
                                ToggleWorldMap()
                            end
                        end
                    end
                end
            else
                -- Fallback : ouvrir la carte générale
                print("[UTT] ERREUR: Pas d'ID d'expédition fourni")
                if not WorldMapFrame:IsShown() then
                    ToggleWorldMap()
                end
            end
        end)
    else
        -- Expédition non disponible : bouton désactivé
        viewButton:SetEnabled(false)
        
        -- Supprimer le script de clic (pas de fonctionnalité)
        viewButton:SetScript("OnClick", nil)
        
        -- Rendre la texture de survol transparente (réutiliser l'existante)
        local highlightTexture = viewButton:GetHighlightTexture()
        if highlightTexture then
            highlightTexture:SetColorTexture(0, 0, 0, 0) -- Transparent
        end
    end
    
    -- Ligne B : Nom et ID (positionnés absolument dans le tiers supérieur)
    -- Position Y : -rowHeight/6 pour être au centre du tiers supérieur
    local namePosY = -rowHeight/6
    
    -- Nom de l'expédition (ligne B)
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", row, "TOPLEFT", deleteButton:GetWidth() + 5 + (config.iconSize or 28) + 12, namePosY)
    nameText:SetText(data.name or "Expédition inconnue")
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    
    -- Vérifier dynamiquement la disponibilité via le service
    local isAvailable = false
    if addon.ExpeditionsService then
        isAvailable = addon.ExpeditionsService:IsAvailable(questID)
    end
    
    -- Couleur selon la disponibilité
    if isAvailable then
        addon.Colors:ApplyRGB(nameText, "AVAILABLE")
    else
        addon.Colors:ApplyRGB(nameText, "UNAVAILABLE")
    end
    
    -- ID de l'expédition (ligne B, après le nom)
    local idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    idText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
    idText:SetText("(ID: " .. questID .. ")")
    idText:SetJustifyH("LEFT")
    idText:SetWordWrap(false)
    local r, g, b, a = addon.Colors:GetRGB("UNAVAILABLE")
    idText:SetTextColor(r, g, b, addon.Colors.ID_TRANSPARENCY)
    
    -- Ligne C : Texte placeholder (positionné dans le tiers inférieur)
    -- Position Y : -rowHeight/2 pour être au centre du tiers inférieur  
    local textPosY = -rowHeight/2
    
    local placeholderText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    placeholderText:SetPoint("TOPLEFT", row, "TOPLEFT", deleteButton:GetWidth() + 5 + (config.iconSize or 28) + 12, textPosY-4)
    placeholderText:SetText("Texte")
    placeholderText:SetJustifyH("LEFT")
    placeholderText:SetWordWrap(false)
    placeholderText:SetTextColor(0.7, 0.7, 0.7, 1) -- Gris pour le placeholder
end

--[[
    Fonction de rendu pour les objets d'inventaire
    @param row Frame - La ligne
    @param deleteButton Button - Le bouton de suppression
    @param itemID number - L'ID de l'objet
    @param data table - Les données de l'objet
    @param config table - La configuration
]]
function addon.ListComponent.RenderInventoryItem(row, deleteButton, itemID, data, config)
    -- Icône de l'objet
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", deleteButton, "RIGHT", 12, 0)
    icon:SetSize(config.iconSize, config.iconSize)
    
    -- Récupérer l'icône : utiliser celle sauvegardée ou récupérer en temps réel
    local iconTexture = data.icon
    if not iconTexture or iconTexture == addon.Textures.DEFAULT_ICON then
        -- Essayer de récupérer l'icône en temps réel
        local _, _, _, _, _, _, _, _, _, realTimeIcon = GetItemInfo(itemID)
        iconTexture = realTimeIcon or addon.Textures.DEFAULT_ICON
    end
    
    icon:SetTexture(iconTexture)
    
    -- Bordure de l'icône
    local iconBorder = row:CreateTexture(nil, "OVERLAY")
    iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
    iconBorder:SetSize(config.iconSize + 6, config.iconSize + 6)
    iconBorder:SetTexture(addon.Textures.ICON_BORDER)
    local r, g, b, a = addon.Colors:GetRGB("MUTED")
    iconBorder:SetVertexColor(r, g, b, 0.8)
    
    -- Nom de l'objet
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", icon, "RIGHT", 12, 0)
    nameText:SetText(data.name or "Inconnu")
    addon.Colors:ApplyRGB(nameText, "NORMAL")
    
    -- ID de l'objet
    local idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    idText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
    idText:SetText("(ID: " .. itemID .. ")")
    local r, g, b, a = addon.Colors:GetRGB("NORMAL")
    idText:SetTextColor(r, g, b, addon.Colors.ID_TRANSPARENCY)
end
