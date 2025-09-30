-- ============================================================================
-- Composant générique d'affichage de listes
-- ============================================================================

local addonName, addon = ...

addon.ListComponent = {}

-- ============================================================================
-- FONCTIONS INTERNES
-- ============================================================================

-- Nettoie toutes les lignes existantes pour éviter les fuites mémoire
local function clearRows(listObject)
    for _, row in pairs(listObject.rows) do
        if row and row.Hide then
            row:Hide()
            row:SetParent(nil)
        end
    end
    wipe(listObject.rows)
end

-- Affiche un message quand la liste est vide
local function showEmptyState(listObject)
    local emptyText = listObject.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("CENTER", listObject.scrollChild, "CENTER", 0, 0)
    emptyText:SetText("Aucun élément")
    emptyText:SetTextColor(0.7, 0.7, 0.7, 1)
    table.insert(listObject.rows, emptyText)
    
    -- S'assurer que le scrollChild a une hauteur minimale pour centrer le texte
    listObject.scrollChild:SetHeight(math.max(100, listObject.scrollFrame:GetHeight()))
    
    -- Désactiver le scroll pour liste vide
    listObject.scrollFrame:EnableMouseWheel(false)
    listObject.scrollFrame:SetVerticalScroll(0)
end

-- ============================================================================
-- API PUBLIQUE
-- ============================================================================

-- Crée une nouvelle liste générique
function addon.ListComponent:Create(parentFrame)
    local container = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    container:SetAllPoints(parentFrame)
    
    -- Style standard : bordure + fond noir
    container:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    container:SetBackdropColor(0, 0, 0, 0.8) -- Fond noir
    container:SetBackdropBorderColor(0.6, 0.6, 0.6, 1) -- Bordure grise
    
    -- Créer la ScrollFrame à droite du container
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -32, 8)
    
    -- Créer le contenu scrollable (où seront placées les rows)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Activer la molette de souris pour le scroll
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - (delta * 20)))
        self:SetVerticalScroll(newScroll)
    end)
    
    local listObject = {
        container = container,
        scrollFrame = scrollFrame,
        scrollChild = scrollChild,
        rows = {},
        deleteCallback = nil,
        renderCallback = nil
    }
    
    -- Met à jour la liste avec de nouvelles données
    function listObject:SetData(dataTable)
        clearRows(self)
        
        if not dataTable or not next(dataTable) then
            showEmptyState(self)
            return
        end
        
        local yOffset = 0
        local rowIndex = 1
        
        for id, data in pairs(dataTable) do
            local row = CreateFrame("Frame", nil, self.scrollChild, "BackdropTemplate")
            row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, yOffset)
            row:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", 0, yOffset)
            row:SetHeight(30)
            
            -- Alternance de couleurs de fond : gris foncé / gris très foncé
            row:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground"
            })
            
            if rowIndex % 2 == 1 then
                row:SetBackdropColor(0.2, 0.2, 0.2, 0) -- Gris foncé pour lignes impaires
            else
                row:SetBackdropColor(0.1, 0.1, 0.1, 0) -- Gris très foncé pour lignes paires
            end
            
            -- Bouton de suppression standard
            local deleteButton = addon.ButtonTemplates.CreateHD_Btn_Delete(row)
            deleteButton:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            deleteButton:SetSize(26, 26)
            deleteButton:SetScript("OnClick", function()
                if self.deleteCallback then
                    self.deleteCallback(id, data)
                end
            end)
            
            -- Contenu personnalisé via callback
            if self.renderCallback then
                self.renderCallback(row, id, data)
            end
            
            table.insert(self.rows, row)
            yOffset = yOffset - 32
            rowIndex = rowIndex + 1
        end
        
        -- Définir la hauteur totale du contenu scrollable
        local totalHeight = math.abs(yOffset) + 16
        local frameHeight = self.scrollFrame:GetHeight()
        self.scrollChild:SetHeight(math.max(totalHeight, frameHeight))
        
        -- Désactiver le scroll si le contenu tient dans la frame
        if totalHeight <= frameHeight then
            self.scrollFrame:EnableMouseWheel(false)
            self.scrollFrame:SetVerticalScroll(0) -- Remettre en haut
        else
            self.scrollFrame:EnableMouseWheel(true)
        end
    end
    
    -- Configure le callback appelé lors de la suppression d'une ligne
    function listObject:DeleteRow(callbackFunction)
        self.deleteCallback = callbackFunction
    end
    
    -- Configure le callback qui crée le contenu personnalisé de chaque ligne
    function listObject:CreateRow(callbackFunction)
        self.renderCallback = callbackFunction
    end
    
    -- Positionnement standard du conteneur
    function listObject:SetPoint(...)
        self.container:SetPoint(...)
    end
    
    return listObject
end


