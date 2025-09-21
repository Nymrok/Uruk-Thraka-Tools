-- ============================================================================
-- CustomScrollFrameSD - ScrollFrame personnalisée avec style minimal
-- ============================================================================

local addonName, addon = ...

addon.CustomScrollFrameSD = {}

-- ============================================================================
-- CONSTANTES
-- ============================================================================

local SCROLL_BAR_WIDTH = 16
local MIN_THUMB_HEIGHT = 20
local SCROLL_STEP = 20 -- Défilement doux de 20px
local BUTTON_HEIGHT = 16 -- Hauteur des boutons de défilement

-- ============================================================================
-- FONCTIONS PRIVÉES
-- ============================================================================

--[[
    Crée un bouton de défilement vers le haut
    @param parent Frame - Le parent
    @return Button - Le bouton créé
]]
local function createUpButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(SCROLL_BAR_WIDTH, BUTTON_HEIGHT)
    
    -- Empêcher l'interaction avec le système de super-tracking
    button:SetAttribute("type", nil)
    button:SetAttribute("action", nil)
    
    -- Texture normale
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetAtlas("minimal-scrollbar-arrow-top")
    button:SetNormalTexture(normalTexture)
    
    -- Texture pressée
    local pushedTexture = button:CreateTexture(nil, "BACKGROUND")
    pushedTexture:SetAllPoints()
    pushedTexture:SetAtlas("minimal-scrollbar-arrow-top-down")
    button:SetPushedTexture(pushedTexture)
    
    -- Texture de survol
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetAtlas("minimal-scrollbar-arrow-top-over")
    button:SetHighlightTexture(highlightTexture)
    
    return button
end

--[[
    Crée un bouton de défilement vers le bas
    @param parent Frame - Le parent
    @return Button - Le bouton créé
]]
local function createDownButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(SCROLL_BAR_WIDTH, BUTTON_HEIGHT)
    
    -- Empêcher l'interaction avec le système de super-tracking
    button:SetAttribute("type", nil)
    button:SetAttribute("action", nil)
    
    -- Texture normale
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetAtlas("minimal-scrollbar-arrow-bottom")
    button:SetNormalTexture(normalTexture)
    
    -- Texture pressée
    local pushedTexture = button:CreateTexture(nil, "BACKGROUND")
    pushedTexture:SetAllPoints()
    pushedTexture:SetAtlas("minimal-scrollbar-arrow-bottom-down")
    button:SetPushedTexture(pushedTexture)
    
    -- Texture de survol
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetAtlas("minimal-scrollbar-arrow-bottom-over")
    button:SetHighlightTexture(highlightTexture)
    
    return button
end

--[[
    Met à jour l'état et la taille du thumb de défilement
    @param scrollFrame ScrollFrame - Le scrollFrame
]]
local function updateThumbLayout(scrollFrame)
    local thumb = scrollFrame.thumb
    local track = scrollFrame.track
    local upButton = scrollFrame.upButton
    local downButton = scrollFrame.downButton
    local scrollChild = scrollFrame:GetScrollChild()
    
    if not scrollChild then return end
    
    local containerHeight = scrollFrame:GetHeight()
    local contentHeight = scrollChild:GetHeight()
    
    -- Position des boutons
    upButton:ClearAllPoints()
    upButton:SetPoint("TOP", track, "TOP", 0, 0)
    
    downButton:ClearAllPoints()
    downButton:SetPoint("BOTTOM", track, "BOTTOM", 0, 0)
    
    -- Hauteur disponible pour le track (sans les boutons)
    local trackHeight = containerHeight - upButton:GetHeight() - downButton:GetHeight()
    track:SetHeight(trackHeight)
    
    if contentHeight <= containerHeight then
        -- Pas besoin de scroll
        thumb:Hide()
    else
        thumb:Show()
        
        -- Calculer la taille du thumb
        local thumbHeight = math.max(MIN_THUMB_HEIGHT, (containerHeight / contentHeight) * trackHeight)
        thumb:SetHeight(thumbHeight)
        
        -- Position du thumb basée sur le scroll actuel
        local currentScroll = scrollFrame:GetVerticalScroll()
        local maxScroll = contentHeight - containerHeight
        local scrollRatio = maxScroll > 0 and (currentScroll / maxScroll) or 0
        local maxThumbPos = trackHeight - thumbHeight
        local thumbPos = scrollRatio * maxThumbPos
        
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -thumbPos - upButton:GetHeight())
    end
end

--[[
    Crée la barre de défilement (thumb) avec trois parties
    @param parent Frame - Le parent
    @return Frame - Le thumb créé
]]
local function createThumb(parent)
    local thumb = CreateFrame("Button", nil, parent)
    thumb:SetWidth(SCROLL_BAR_WIDTH)
    thumb:SetHeight(MIN_THUMB_HEIGHT)
    
    -- Empêcher l'interaction avec le système de super-tracking
    thumb:SetAttribute("type", nil)
    thumb:SetAttribute("action", nil)
    
    -- Partie haute du thumb
    local topTexture = thumb:CreateTexture(nil, "BACKGROUND")
    topTexture:SetPoint("TOP")
    topTexture:SetSize(SCROLL_BAR_WIDTH, 5)
    topTexture:SetAtlas("minimal-scrollbar-thumb-top")
    thumb.topTexture = topTexture
    
    local topPushedTexture = thumb:CreateTexture(nil, "BACKGROUND")
    topPushedTexture:SetPoint("TOP")
    topPushedTexture:SetSize(SCROLL_BAR_WIDTH, 5)
    topPushedTexture:SetAtlas("minimal-scrollbar-thumb-top-down")
    topPushedTexture:Hide()
    thumb.topPushedTexture = topPushedTexture
    
    local topHighlightTexture = thumb:CreateTexture(nil, "HIGHLIGHT")
    topHighlightTexture:SetPoint("TOP")
    topHighlightTexture:SetSize(SCROLL_BAR_WIDTH, 5)
    topHighlightTexture:SetAtlas("minimal-scrollbar-thumb-top-over")
    thumb.topHighlightTexture = topHighlightTexture
    
    -- Partie basse du thumb
    local bottomTexture = thumb:CreateTexture(nil, "BACKGROUND")
    bottomTexture:SetPoint("BOTTOM")
    bottomTexture:SetSize(SCROLL_BAR_WIDTH, 5)
    bottomTexture:SetAtlas("minimal-scrollbar-thumb-bottom")
    thumb.bottomTexture = bottomTexture
    
    local bottomPushedTexture = thumb:CreateTexture(nil, "BACKGROUND")
    bottomPushedTexture:SetPoint("BOTTOM")
    bottomPushedTexture:SetSize(SCROLL_BAR_WIDTH, 5)
    bottomPushedTexture:SetAtlas("minimal-scrollbar-thumb-bottom-down")
    bottomPushedTexture:Hide()
    thumb.bottomPushedTexture = bottomPushedTexture
    
    local bottomHighlightTexture = thumb:CreateTexture(nil, "HIGHLIGHT")
    bottomHighlightTexture:SetPoint("BOTTOM")
    bottomHighlightTexture:SetSize(SCROLL_BAR_WIDTH, 5)
    bottomHighlightTexture:SetAtlas("minimal-scrollbar-thumb-bottom-over")
    thumb.bottomHighlightTexture = bottomHighlightTexture
    
    -- Partie centrale du thumb
    local middleTexture = thumb:CreateTexture(nil, "BACKGROUND")
    middleTexture:SetPoint("TOP", topTexture, "BOTTOM")
    middleTexture:SetPoint("BOTTOM", bottomTexture, "TOP")
    middleTexture:SetWidth(SCROLL_BAR_WIDTH)
    middleTexture:SetAtlas("minimal-scrollbar-thumb-middle")
    thumb.middleTexture = middleTexture
    
    local middlePushedTexture = thumb:CreateTexture(nil, "BACKGROUND")
    middlePushedTexture:SetPoint("TOP", topTexture, "BOTTOM")
    middlePushedTexture:SetPoint("BOTTOM", bottomTexture, "TOP")
    middlePushedTexture:SetWidth(SCROLL_BAR_WIDTH)
    middlePushedTexture:SetAtlas("minimal-scrollbar-thumb-middle-down")
    middlePushedTexture:Hide()
    thumb.middlePushedTexture = middlePushedTexture
    
    local middleHighlightTexture = thumb:CreateTexture(nil, "HIGHLIGHT")
    middleHighlightTexture:SetPoint("TOP", topTexture, "BOTTOM")
    middleHighlightTexture:SetPoint("BOTTOM", bottomTexture, "TOP")
    middleHighlightTexture:SetWidth(SCROLL_BAR_WIDTH)
    middleHighlightTexture:SetAtlas("minimal-scrollbar-thumb-middle-over")
    thumb.middleHighlightTexture = middleHighlightTexture
    
    -- Gestion des états visuels
    thumb:SetScript("OnMouseDown", function()
        topTexture:Hide()
        bottomTexture:Hide()
        middleTexture:Hide()
        topPushedTexture:Show()
        bottomPushedTexture:Show()
        middlePushedTexture:Show()
    end)
    
    thumb:SetScript("OnMouseUp", function()
        topPushedTexture:Hide()
        bottomPushedTexture:Hide()
        middlePushedTexture:Hide()
        topTexture:Show()
        bottomTexture:Show()
        middleTexture:Show()
    end)
    
    -- Texture de survol combinée
    local combinedHighlight = thumb:CreateTexture(nil, "HIGHLIGHT")
    combinedHighlight:SetAllPoints()
    combinedHighlight:SetColorTexture(1, 1, 1, 0.1)
    thumb:SetHighlightTexture(combinedHighlight)
    
    return thumb
end

--[[
    Crée le track de fond avec trois parties
    @param parent Frame - Le parent
    @return Frame - Le track créé
]]
local function createTrack(parent)
    local track = CreateFrame("Frame", nil, parent)
    track:SetWidth(SCROLL_BAR_WIDTH)
    
    -- Partie haute du track
    local topTexture = track:CreateTexture(nil, "BACKGROUND")
    topTexture:SetPoint("TOP")
    topTexture:SetSize(SCROLL_BAR_WIDTH, 5)
    topTexture:SetAtlas("minimal-scrollbar-track-top")
    
    -- Partie basse du track
    local bottomTexture = track:CreateTexture(nil, "BACKGROUND")
    bottomTexture:SetPoint("BOTTOM")
    bottomTexture:SetSize(SCROLL_BAR_WIDTH, 5)
    bottomTexture:SetAtlas("minimal-scrollbar-track-bottom")
    
    -- Partie centrale du track
    local middleTexture = track:CreateTexture(nil, "BACKGROUND")
    middleTexture:SetPoint("TOP", topTexture, "BOTTOM")
    middleTexture:SetPoint("BOTTOM", bottomTexture, "TOP")
    middleTexture:SetWidth(SCROLL_BAR_WIDTH)
    middleTexture:SetAtlas("!minimal-scrollbar-track-middle")
    
    return track
end

-- ============================================================================
-- FONCTION PUBLIQUE DE CRÉATION
-- ============================================================================

--[[
    Crée une CustomScrollFrameSD
    @param parent Frame - Le frame parent
    @param width number - Largeur de la zone de contenu
    @param height number - Hauteur de la zone de contenu
    @return ScrollFrame - La CustomScrollFrameSD créée
]]
function addon.CustomScrollFrameSD:Create(parent, width, height)
    width = width or 400
    height = height or 300
    
    -- Frame principal conteneur
    local mainFrame = CreateFrame("Frame", nil, parent)
    mainFrame:SetSize(width, height)
    
    -- ScrollFrame pour le contenu
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame)
    scrollFrame:SetSize(width - SCROLL_BAR_WIDTH, height)
    scrollFrame:SetPoint("TOPLEFT")
    scrollFrame:EnableMouseWheel(true)
    
    -- ScrollChild pour le contenu
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(width - SCROLL_BAR_WIDTH, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Track de fond
    local track = createTrack(mainFrame)
    track:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    track:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    scrollFrame.track = track
    
    -- Boutons Up et Down (créés avec les atlas minimal-scrollbar)
    local upButton = createUpButton(track)
    local downButton = createDownButton(track)
    scrollFrame.upButton = upButton
    scrollFrame.downButton = downButton
    
    -- Thumb de défilement
    local thumb = createThumb(track)
    scrollFrame.thumb = thumb
    
    -- ScrollChild accessible
    scrollFrame.scrollChild = scrollChild
    scrollFrame.mainFrame = mainFrame
    
    -- Gestion de la molette
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentScroll = self:GetVerticalScroll()
        local contentHeight = scrollChild:GetHeight()
        local containerHeight = self:GetHeight()
        local maxScroll = math.max(0, contentHeight - containerHeight)
        
        local newScroll = currentScroll - (delta * SCROLL_STEP)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
        updateThumbLayout(scrollFrame)
    end)
    
    -- Boutons de défilement
    upButton:SetScript("OnClick", function()
        local currentScroll = scrollFrame:GetVerticalScroll()
        local newScroll = math.max(0, currentScroll - SCROLL_STEP)
        scrollFrame:SetVerticalScroll(newScroll)
        updateThumbLayout(scrollFrame)
    end)
    
    downButton:SetScript("OnClick", function()
        local currentScroll = scrollFrame:GetVerticalScroll()
        local contentHeight = scrollChild:GetHeight()
        local containerHeight = scrollFrame:GetHeight()
        local maxScroll = math.max(0, contentHeight - containerHeight)
        local newScroll = math.min(maxScroll, currentScroll + SCROLL_STEP)
        scrollFrame:SetVerticalScroll(newScroll)
        updateThumbLayout(scrollFrame)
    end)
    
    -- Dragging du thumb
    thumb:EnableMouse(true)
    thumb:SetMovable(true)
    thumb:RegisterForDrag("LeftButton")
    
    thumb:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self.isDragging = true
    end)
    
    thumb:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.isDragging = false
        updateThumbLayout(scrollFrame)
    end)
    
    -- Click sur le track pour sauter à une position
    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not thumb:IsMouseOver() then
            local cursorY = select(2, GetCursorPosition()) / self:GetEffectiveScale()
            local trackTop = self:GetTop()
            local trackHeight = self:GetHeight()
            local clickPos = (trackTop - cursorY) / trackHeight
            
            local contentHeight = scrollChild:GetHeight()
            local containerHeight = scrollFrame:GetHeight()
            local maxScroll = math.max(0, contentHeight - containerHeight)
            
            local newScroll = clickPos * maxScroll
            newScroll = math.max(0, math.min(newScroll, maxScroll))
            scrollFrame:SetVerticalScroll(newScroll)
            updateThumbLayout(scrollFrame)
        end
    end)
    
    -- Fonction de mise à jour du layout
    function scrollFrame:UpdateLayout()
        updateThumbLayout(self)
    end
    
    -- Fonction pour remettre le scroll en haut
    function scrollFrame:ScrollToTop()
        self:SetVerticalScroll(0)
        updateThumbLayout(self)
    end
    
    -- Fonction pour aller tout en bas
    function scrollFrame:ScrollToBottom()
        local contentHeight = scrollChild:GetHeight()
        local containerHeight = self:GetHeight()
        local maxScroll = math.max(0, contentHeight - containerHeight)
        self:SetVerticalScroll(maxScroll)
        updateThumbLayout(self)
    end
    
    -- Mise à jour initiale
    C_Timer.After(0.1, function()
        scrollFrame:UpdateLayout()
    end)
    
    return scrollFrame
end