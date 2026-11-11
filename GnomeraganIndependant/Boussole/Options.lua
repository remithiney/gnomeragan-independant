--[[
  Boussole — panneau d'options, mode Édition, commandes, raccourci, reprise des réglages DAoCCompass.
]]

local _, GI = ...
local M = GI.modules.Boussole

local floor, max, min = math.floor, math.max, math.min
local format = string.format
local BRONZE = M.BRONZE
local band = M.band

local db

---------------------------------------------------------------------------
-- Panneau d'options (créé à la première ouverture)
---------------------------------------------------------------------------
local panel
local checks, sliders = {}, {}

local function RefreshPanel()
	if not panel then
		return
	end
	for i = 1, #checks do
		checks[i]:SetChecked(db[checks[i].key])
	end
	for i = 1, #sliders do
		local s = sliders[i]
		s.updating = true
		s:SetValue(s.get())
		s.updating = false
		s.val:SetText(s.fmt(s.get()))
	end
end

local function CreatePanel()
	panel = CreateFrame("Frame", "GnomeraganBoussoleOptions", UIParent)
	panel:SetSize(270, 520)
	panel:SetFrameStrata("DIALOG")
	panel:SetClampedToScreen(true)
	panel:SetMovable(true)
	panel:EnableMouse(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
	panel:Hide()

	local pbg = panel:CreateTexture(nil, "BACKGROUND")
	pbg:SetAllPoints()
	pbg:SetColorTexture(0.05, 0.045, 0.035, 0.95)
	M.Frame4(panel, BRONZE[1], BRONZE[2], BRONZE[3], 1, 2)

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 12, -10)
	title:SetText("Boussole — options")

	local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 2)

	local y = -34
	local function Header(text)
		local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetPoint("TOPLEFT", 12, y)
		fs:SetText(text)
		fs:SetTextColor(BRONZE[1] + 0.2, BRONZE[2] + 0.2, BRONZE[3] + 0.1)
		y = y - 16
	end

	local function Check(label, key)
		local cb = CreateFrame("CheckButton", nil, panel)
		cb:SetSize(22, 22)
		cb:SetPoint("TOPLEFT", 10, y)
		cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
		cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
		cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
		cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
		fs:SetText(label)
		cb.key = key
		cb:SetScript("OnClick", function(self)
			db[key] = self:GetChecked() and true or false
			M.OnSettingChanged(key)
		end)
		checks[#checks + 1] = cb
		y = y - 22
	end

	local function Slider(label, minV, maxV, step, get, set, fmt)
		y = y - 14
		local s = CreateFrame("Slider", nil, panel)
		s:SetOrientation("HORIZONTAL")
		s:SetSize(170, 16)
		s:SetPoint("TOPLEFT", 16, y)
		s:SetMinMaxValues(minV, maxV)
		s:SetValueStep(step)
		if s.SetObeyStepOnDrag then
			s:SetObeyStepOnDrag(true)
		end
		s:EnableMouseWheel(true)
		local track = s:CreateTexture(nil, "BACKGROUND")
		track:SetColorTexture(0, 0, 0, 0.8)
		track:SetHeight(6)
		track:SetPoint("LEFT")
		track:SetPoint("RIGHT")
		s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		local thumb = s:GetThumbTexture()
		if thumb then
			thumb:SetSize(32, 32)
		end
		local t = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		t:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 1)
		t:SetText(label)
		s.val = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		s.val:SetPoint("LEFT", s, "RIGHT", 10, 0)
		s.get, s.fmt = get, fmt
		s:SetScript("OnValueChanged", function(self, v)
			if self.updating then
				return
			end
			v = floor(v / step + 0.5) * step
			set(v)
			self.val:SetText(fmt(v))
			M.ApplySettings()
		end)
		s:SetScript("OnMouseWheel", function(self, delta)
			self:SetValue(max(minV, min(maxV, self:GetValue() + delta * step)))
		end)
		sliders[#sliders + 1] = s
		y = y - 24
	end

	local function Percent(v)
		return format("%d %%", v)
	end
	local function Plain(v)
		return format("%d", v)
	end

	Header("Marqueurs")
	Check("Direction de Gnomeregan", "showHome")
	Check("Membres du groupe (couleur de classe)", "showParty")
	Check("Tout le raid (sinon : mon sous-groupe)", "showRaid")
	Check("Icônes de raid (crâne, croix…)", "raidIcons")
	Check("Entourer les soignants", "healers")
	Check("Ma cible (si membre du groupe)", "showTarget")
	Check("Pings du groupe (le membre clignote)", "showPings")
	Check("Repère de carte", "showWaypoint")
	Check("Quête suivie", "showQuest")
	Check("Garder au bord ce qui est hors champ", "showEdges")
	y = y - 6
	Header("Affichage")
	Check("Petits nombres de degrés sur la bande", "showDegrees")
	Check("Cap sous la bande (ex. : O 270°)", "showHeading")
	Check("Distances (cible, repère, quête, Gnomeregan)", "showDist")
	Check("Coordonnées", "showCoords")
	Check("Nom de la zone", "showZone")
	Check("Soleil / lune", "celest")
	Check("Bouton d'invitation de la guilde (à droite)", "showInvite")

	Slider("Champ de vision", 60, 360, 10, function()
		return db.fov
	end, function(v)
		db.fov = v
	end, function(v)
		return format("%d°", v)
	end)
	Slider("Portée des membres (0 = illimitée)", 0, 300, 10, function()
		return db.range
	end, function(v)
		db.range = v
	end, function(v)
		return v == 0 and "illimitée" or format("%d m", v)
	end)
	Slider("Taille des marqueurs", 6, 20, 1, function()
		return db.markerSize
	end, function(v)
		db.markerSize = v
	end, Plain)
	Slider("Taille des directions (N, E, S, O)", 10, 26, 1, function()
		return db.dirSize
	end, function(v)
		db.dirSize = v
	end, Plain)
	Slider("Opacité du fond", 0, 100, 5, function()
		return floor(db.bgAlpha * 100 + 0.5)
	end, function(v)
		db.bgAlpha = v / 100
	end, Percent)
	Slider("Opacité générale", 10, 100, 5, function()
		return floor(db.alpha * 100 + 0.5)
	end, function(v)
		db.alpha = v / 100
	end, Percent)
	Slider("Échelle", 50, 200, 5, function()
		return floor(db.scale * 100 + 0.5)
	end, function(v)
		M.SetScale(v / 100)
	end, Percent)
	Slider("Fluidité (images par seconde)", 10, 60, 5, function()
		return db.fps
	end, function(v)
		db.fps = v
	end, Plain)

	panel:SetHeight(-y + 10)
end

local function TogglePanel(show)
	if not panel then
		CreatePanel()
	end
	if show == nil then
		show = not panel:IsShown()
	end
	if show then
		RefreshPanel()
		if not panel.placed then
			panel:ClearAllPoints()
			panel:SetPoint("TOP", band, "BOTTOM", 0, -80)
			panel.placed = true
		end
		panel:Show()
	else
		panel:Hide()
	end
end

---------------------------------------------------------------------------
-- Calque de déplacement (mode Édition ou /boussole deplacer)
---------------------------------------------------------------------------
local function SaveLayout()
	local p, _, rp, x, y = band:GetPoint()
	db.point = { p, rp, x, y }
	db.width = floor(band:GetWidth() + 0.5)
	db.height = floor(band:GetHeight() + 0.5)
end

local overlay = CreateFrame("Frame", nil, M.border)
overlay:SetPoint("TOPLEFT", band, "TOPLEFT", -28, 12)
overlay:SetPoint("BOTTOMRIGHT", band, "BOTTOMRIGHT", 6, -10)
overlay:SetFrameLevel(M.border:GetFrameLevel() + 20)
overlay:EnableMouse(true)
overlay:EnableMouseWheel(true)
overlay:RegisterForDrag("LeftButton")
overlay:Hide()
M.overlay = overlay
do
	local fill = overlay:CreateTexture(nil, "BACKGROUND")
	fill:SetAllPoints()
	fill:SetColorTexture(0.1, 0.45, 0.95, 0.22)
	M.Frame4(overlay, 0.35, 0.7, 1, 0.95, 2)
	local t = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	t:SetPoint("BOTTOM", overlay, "TOP", 0, 2)
	t:SetText("Boussole — clic : options")
end

overlay:SetScript("OnMouseDown", function(self)
	self.dragged = false
end)
overlay:SetScript("OnDragStart", function(self)
	self.dragged = true
	band:StartMoving()
end)
overlay:SetScript("OnDragStop", function()
	band:StopMovingOrSizing()
	SaveLayout()
end)
overlay:SetScript("OnMouseUp", function(self)
	if not self.dragged then
		TogglePanel()
	end
end)
overlay:SetScript("OnMouseWheel", function(_, delta)
	db.fov = max(60, min(360, db.fov + delta * 10))
	RefreshPanel()
end)
overlay:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:AddLine("Boussole")
	GameTooltip:AddLine("Clic : options", 1, 1, 1)
	GameTooltip:AddLine("Glisser : déplacer", 1, 1, 1)
	GameTooltip:AddLine("Coin bas-droit : redimensionner", 1, 1, 1)
	GameTooltip:AddLine("Molette : champ de vision", 1, 1, 1)
	GameTooltip:Show()
end)
overlay:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

local grip = CreateFrame("Button", nil, overlay)
grip:SetSize(16, 16)
grip:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -1, 1)
grip:SetFrameLevel(overlay:GetFrameLevel() + 2)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
grip:SetScript("OnMouseDown", function()
	band:StartSizing("BOTTOMRIGHT")
end)
grip:SetScript("OnMouseUp", function()
	band:StopMovingOrSizing()
	SaveLayout()
end)

local function HookEditMode()
	if not EventRegistry then
		return
	end
	EventRegistry:RegisterCallback("EditMode.Enter", function()
		M.editMode = true
		M.ApplySettings()
	end, M)
	EventRegistry:RegisterCallback("EditMode.Exit", function()
		M.editMode = false
		if panel then
			panel:Hide()
		end
		M.ApplySettings()
	end, M)
	if EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive and EditModeManagerFrame:IsEditModeActive() then
		M.editMode = true
	end
end

---------------------------------------------------------------------------
-- Commandes : /gi boussole …, /boussole …, /bsl …
---------------------------------------------------------------------------
local HELP = {
	"|cffffd100/boussole|r — afficher / masquer (aussi : /bsl, /gi boussole)",
	"|cffffd100/boussole options|r — panneau d'options (aussi : clic sur la bande en mode Édition)",
	"Mode Édition : glisser = déplacer, coin = redimensionner, molette = champ de vision.",
	"|cffffd100/boussole deplacer|r — déplacer / redimensionner hors mode Édition (bascule)",
	"|cffffd100/boussole loc|r — position et cap dans le chat",
	"|cffffd100/boussole reset|r — position et taille par défaut",
	"Médaillon bleu : Gnomeregan. Repère vert : Ctrl+clic sur la carte. Quête jaune : quête suivie.",
	"Anneau orange autour d'un membre : il vient de faire un ping.",
	"Icône à droite de la bande : inviter les membres de la guilde présents dans votre zone.",
	"|cffffd100/boussole diag|r — diagnostic (événements reçus, réglages)",
}

local function PrintLoc()
	M.UpdatePlayerWorld()
	local h = M.GetHeading()
	local x, y = M.PlayerMapFrac()
	local zone = (GetMinimapZoneText and GetMinimapZoneText()) or GetZoneText() or "?"
	GI:Print(
		format(
			"%s — %s — cap %s",
			zone,
			x and format("%.1f, %.1f", x * 100, y * 100) or "position inconnue",
			h and format("%d° %s", floor(h + 0.5) % 360, M.DirName(h)) or "inconnu"
		)
	)
	-- pour caler Gnomeregan : carte et position monde exactes
	if M.pN then
		GI:Print(
			format(
				"|cff8c8c8ccarte %s, monde %.1f / %.1f, continent %s|r",
				tostring(M.curMap),
				M.pN,
				M.pW,
				tostring(M.pInst)
			)
		)
	end
end

function M:OnSlash(msg)
	local cmd = (msg or ""):lower():match("^%s*(%S*)")
	if cmd == "" then
		M.Toggle()
	elseif cmd == "aide" or cmd == "help" or cmd == "?" then
		for _, line in ipairs(HELP) do
			GI:Print(line)
		end
	elseif cmd == "options" or cmd == "config" or cmd == "opt" then
		TogglePanel(true)
	elseif cmd == "deplacer" or cmd == "déplacer" or cmd == "move" then
		db.locked = not db.locked
		M.ApplySettings()
		GI:Print(
			db.locked and "boussole verrouillée."
				or "déverrouillée — glissez pour déplacer, coin pour redimensionner."
		)
	elseif cmd == "loc" then
		PrintLoc()
	elseif cmd == "diag" or cmd == "debug" then
		M.debug = not M.debug
		GI:Print(
			"diagnostic " .. (M.debug and "activé : faites un ping en groupe, changez de cible." or "désactivé.")
		)
		if M.debug then
			GI:Print(
				format(
					"[diag] réglages DAoCCompass repris : %s ; pings %s ; cible %s ; groupé : %s",
					db.imported and "oui" or "non",
					db.showPings and "oui" or "non",
					db.showTarget and "oui" or "non",
					IsInGroup() and "oui" or "non"
				)
			)
			local refused = GI.refusedEvents
			GI:Print(
				"[diag] événements refusés par le jeu : "
					.. (#refused > 0 and table.concat(refused, ", ") or "aucun")
			)
		end
	elseif cmd == "reset" then
		M.ResetLayout()
		RefreshPanel()
		GI:Print("position et taille de la boussole réinitialisées.")
	else
		GI:Print("commande inconnue. Tapez /boussole aide")
	end
end

SLASH_GIBOUSSOLE1 = "/boussole"
SLASH_GIBOUSSOLE2 = "/bsl"
SlashCmdList.GIBOUSSOLE = function(msg)
	M:OnSlash(msg)
end

-- Raccourci clavier (Bindings.xml)
BINDING_HEADER_GNOMERAGAN = "Gnomeragan Indépendant"
BINDING_NAME_GNOMERAGAN_BOUSSOLE = "Afficher / masquer la boussole"
function GnomeraganIndependant_ToggleBoussole()
	M.Toggle()
end

---------------------------------------------------------------------------
-- Démarrage
---------------------------------------------------------------------------
-- Reprend une fois les réglages de l'ancien addon DAoCCompass (s'il est encore activé)
local function ImportDAoCCompass()
	local old = DAoCCompassDB
	if db.imported or type(old) ~= "table" then
		return
	end
	for k in pairs(M.defaults) do
		local v = old[k]
		if v ~= nil and type(v) == type(M.defaults[k]) then
			db[k] = v
		end
	end
	if type(old.point) == "table" and #old.point == 4 then
		db.point = { old.point[1], old.point[2], old.point[3], old.point[4] }
	end
	db.imported = true
	GI:Print("réglages de DAoCCompass repris. Vous pouvez désactiver l'ancien addon DAoCCompass.")
end

function M:OnEnable()
	db = M.db
	ImportDAoCCompass()
	M.InitBande()
	HookEditMode()
	M.ApplySettings()
end
