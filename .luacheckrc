-- Analyse statique de l'addon (Lua 5.1, comme WoW)
std = "lua51"
max_line_length = 120
codes = true

-- Seules globales que l'addon a le droit de créer
globals = {
	"GnomeraganIndependantDB",
	"SlashCmdList",
}
-- SLASH_* et BINDING_* : créées par l'addon, lues par le jeu
files["**/*.lua"] = {
	globals = {
		"SLASH_GNOMERAGAN1",
		"SLASH_GNOMERAGAN2",
		"SLASH_GIBOUSSOLE1",
		"SLASH_GIBOUSSOLE2",
		"BINDING_HEADER_GNOMERAGAN",
		"BINDING_NAME_GNOMERAGAN_BOUSSOLE",
		"GnomeraganIndependant_ToggleBoussole",
	},
}

-- L'API de WoW est trop vaste pour être listée ici : on n'avertit pas sur la LECTURE
-- d'une globale inconnue (113), mais on interdit d'en ÉCRIRE une (111, 112).
-- Les tests imitent l'API WoW : ils créent forcément des globales
files["tests/*.lua"] = {
	ignore = { "111", "112", "121", "122" },
}

ignore = {
	"113",
	"212/self", -- argument self inutilisé dans les méthodes
}
