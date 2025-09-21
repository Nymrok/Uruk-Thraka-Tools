-- ============================================================================
-- Collection de templates réutilisables pour les boutons d'interface
-- Ce fichier charge tous les templates de boutons depuis le répertoire Templates
-- ============================================================================

local addonName, addon = ...

-- Initialisation du namespace pour les templates de boutons
addon.ButtonTemplates = addon.ButtonTemplates or {}

--[[
    STRUCTURE DU RÉPERTOIRE TEMPLATES :
    
    UI/Templates/
    ├── HD_Btn_RedGrey.lua       - Boutons rouges standard avec texte
    ├── HD_Btn_RedGold.lua       - Boutons gold avec texte
    ├── HD_Btn_VisibilityOn.lua  - Boutons avec icône œil (vue/visibilité)
    ├── HD_Btn_Delete.lua        - Boutons de suppression HD
    ├── HD_Btn_Exit.lua          - Boutons de sortie/fermeture HD
    ├── HD_Btn_Refresh.lua       - Boutons de rafraîchissement
    ├── HD_Btn_Plus.lua          - Boutons d'ajout HD avec icône plus
    ├── AddButtonSD.lua          - Boutons d'ajout standard avec icône plus
    ├── InfoButton.lua           - Boutons d'information
    ├── HD_Btn_ArrowUp.lua       - Boutons de défilement vers le haut
    ├── HD_Btn_ArrowDown.lua     - Boutons de défilement vers le bas
    └── CustomScrollFrameSD.lua  - Template de scrollframe style minimal
    
    USAGE :
    
    local myButton = addon.ButtonTemplates.CreateHD_Btn_RedGrey(parent, "Mon Texte", 150, 40)
    local viewBtn = addon.ButtonTemplates.CreateHD_Btn_VisibilityOn(parent, 32)
    local scrollFrame = addon.CustomScrollFrameSD:Create(parent, 400, 300)
]]

-- ============================================================================
-- NOTE : Les fichiers de templates individuels sont chargés automatiquement
-- par le système de chargement de WoW via le fichier .toc
-- 
-- Chaque template maintient le namespace addon.ButtonTemplates et définit
-- sa propre fonction Create*
-- ============================================================================

