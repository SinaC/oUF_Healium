-- Ripped from Tukui

local H, C, L, oUF = unpack(select(2, ...))

if GetLocale() == "frFR" then
	L.unitframes_ouf_offline = "Hors ligne"
	L.unitframes_ouf_dead = "Mort"
	L.unitframes_ouf_ghost = "Fantome"

	L.healium_CHECKSPELL_SPELLNOTLEARNED = "Le sort %s(%d) n'est pas connu"
	L.healium_CHECKSPELL_SPELLNOTEXISTS = "Le sort %d n'existe pas"
	L.healium_CHECKSPELL_MACRONOTFOUND = "La macro %s n'existe pas"
	L.healium_TOOLTIP_UNKNOWNSPELL = "Sort %s(%d) inconnu"
	L.healium_TOOLTIP_UNKNOWN_MACRO = "Macro %s inconnue"
	L.healium_TOOLTIP_UNKNOWN = "Inconnu"
	L.healium_TOOLTIP_MACRO = "Macro %s"
	L.healium_TOOLTIP_TARGET = "Cible: |cFF00FF00%s|r"
	L.healium_BUFFDEBUFF_TOOMANYBUFF = "Trop d'am\195\169liorations sur %s %s"
	L.healium_BUFFDEBUFF_TOOMANYDEBUFF = "Trop d'affaiblissements sur %s %s"
	L.healium_GREETING_VERSIONUNKNOWN = "Num\195\169ro de version non-disponible"
	L.healium_GREETING_VERSION = "Version %s"
	L.healium_GREETING_OPTIONS = "Utilisez /th pour obtenir une liste des commandes"
	L.healium_CONSOLE_HELP_GENERAL =        "Commandes pour %s or %s"
	L.healium_CONSOLE_HELP_DEBUG =          " debug - alterne entre le mode debug et le mode release"
	L.healium_CONSOLE_HELP_DUMPGENERAL =    " dump - affiche les informations \195\160 propos des Fen\195\170tres Healium"
	L.healium_CONSOLE_HELP_DUMPUNIT =       " dump [unit] - affiche les informations \195\160 propos d'une unit\195\169"
	L.healium_CONSOLE_HELP_DUMPPERF =       " dump perf - affiche les compteurs de performance"
	L.healium_CONSOLE_HELP_DUMPSHOW =       " dump show - affiche la fen\195\170tre de dump"
	L.healium_CONSOLE_HELP_RESETPERF =      " reset perf - remet \195\160 z\195\169ro les compteurs de performance"
	L.healium_CONSOLE_HELP_REFRESH =        " refresh - r\195\169initialise toutes les fen\195\170tres Healium"
	L.healium_CONSOLE_HELP_TOGGLE =         " toggle raid||tank|pet|namelist - affiche ou cache une fen\195\170tre"
	L.healium_CONSOLE_HELP_NAMELISTADD =    " namelist add [name] - ajoute le joueur ou la cible � la namelist"
	L.healium_CONSOLE_HELP_NAMELISTREMOVE = " namelist remove [name] - retire le joueur ou la cible � la namelist"
	L.healium_CONSOLE_HELP_NAMELISTCLEAR =  " namelist clear - vide la namelist list"
	L.healium_CONSOLE_DEBUG_ENABLED = "Mode debug activ\195\169"
	L.healium_CONSOLE_DEBUG_DISABLED = "Mode release activ\195\169"
	L.healium_CONSOLE_DUMP_UNITNOTFOUND = "Fen\195\170tre pour l'unit\195\169 %s introuvable"
	L.healium_CONSOLE_RESET_PERF = "Les compteurs de performance ont \195\169t\195\169 remis \195\160 z\195\169ro"
	L.healium_CONSOLE_REFRESH_NOTINCOMBAT = "Impossible durant un combat"
	L.healium_CONSOLE_REFRESH_OK = "Fen\195\170tres Healium r\195\169initialis\195\169es"
	L.healium_CONSOLE_TOGGLE_INVALID = "Choix valide: raid|tank|pet|namelist"
	L.healium_CONSOLE_NAMELIST_ADDREMOVEINVALID = "Joueur non valide ou inexistant"
	L.healium_CONSOLE_NAMELIST_ADDALREADY = "Ce joueur est d\195\169j\195\160 dans la namelist"
	L.healium_CONSOLE_NAMELIST_REMOVENOTFOUND = "Ce joueur n'est pas dans la namelist"
	L.healium_CONSOLE_NAMELIST_INVALIDOPTION = "Option de gestion de namelist non-valide"
	L.healium_CONSOLE_NAMELIST_ADDED = "%s ajout\195\169 \195\160 la namelist"
	L.healium_CONSOLE_NAMELIST_REMOVED = "%s retir\195\169 de la namelist"
	L.healium_CONSOLE_NAMELIST_CLEARED = "La namelist a \195\169t\195\169 remise \195\160 z\195\169ro"
	L.healium_SETTINGS_UNKNOWNBUFFDEBUFF = "SpellID %d inconnu dans %s"
	L.healium_SETTINGS_DUPLICATEBUFFDEBUFF = "SpellID %d et %d sont le m\195\170me buff/debuff (%s) dans %s"
	L.healium_TAB_TITLE = "Menu Healium"
	L.healium_TAB_TOOLTIP = "Healium: cliquer pour les options"
	L.healium_TAB_TANKFRAMESHOW = "Afficher la fen\195\170tre des tanks"
	L.healium_TAB_TANKFRAMEHIDE = "Cacher la fen\195\170tre des tanks"
	L.healium_TAB_PETFRAMESHOW = "Afficher la fen\195\170tre des familiers"
	L.healium_TAB_PETFRAMEHIDE = "Cacher la fen\195\170tre des familiers"
	L.healium_TAB_NAMELISTFRAMESHOW = "Afficher la fen\195\170tre namelist"
	L.healium_TAB_NAMELISTFRAMEHIDE = "Cacher la fen\195\170tre namelist"
end
