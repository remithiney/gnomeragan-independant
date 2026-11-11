--[[
  Boussole — le cor de l'appel aux armes, à droite de la bande.
  Invite les membres de la guilde présents dans la même zone.
  Le clic ouvre une liste ; le joueur choisit qui inviter (rien d'automatique).
  La liste est créée à la première ouverture ; GUILD_ROSTER_UPDATE n'est suivi que liste ouverte.
  GetGuildRosterInfo n'est pas documentée dans ForeverAPI : chaque valeur est vérifiée (type, secret).
]]

local _, GI = ...
local M = GI.modules.Boussole

local format = string.format
local GetTime = GetTime
local IsSecret = GI.IsSecret

local ICON = "Interface\\Icons\\INV_Misc_Horn_01"
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local MAX_ROWS = 15
local ROW_H = 16
local LIST_W = 230
local TOP = -44 -- sous le titre et la zone
local INVITE_COOLDOWN = 60 -- secondes avant de pouvoir réinviter la même personne
local BRONZE = M.BRONZE

local T = {
	title = "Appel aux armes",
	hint = "Sonnez le cor pour rallier les Gnomeragan présents dans la zone.",
	noGuild = "Sans guilde, nul ne répondra à votre cor.",
	notLeader = "Seul le chef du groupe peut sonner l'appel.",
	none = "Aucun compagnon à portée de cor.",
	more = "… et %d autres",
	invited = "appelé",
	all = "Sonner l'appel (%d)",
	sent = "le cor retentit : appel lancé à %s.",
	unknownZone = "terres inconnues",
}

---------------------------------------------------------------------------
-- Données : membres de la guilde en ligne, dans ma zone, hors de mon groupe
---------------------------------------------------------------------------
local found = {} -- noms complets (Nom-Royaume), réutilisés d'un appel à l'autre
local foundShort, foundLevel, foundClass = {}, {}, {}
local nFound = 0
local invitedAt = {} -- [nom complet] = GetTime() de l'invitation

local function Str(v)
	if IsSecret(v) or type(v) ~= "string" or v == "" then
		return nil
	end
	return v
end

-- UnitInParty : booléen ; UnitInRaid : numéro dans le raid ou nil
local function InMyGroup(short)
	local p, r = UnitInParty(short), UnitInRaid(short)
	return (not IsSecret(p) and p) or (not IsSecret(r) and r ~= nil)
end

local function Scan()
	nFound = 0
	local zone = Str(GetRealZoneText())
	if not zone or not IsInGuild() then
		return zone
	end
	local me = Str(UnitName("player"))
	local total = GetNumGuildMembers()
	if IsSecret(total) or type(total) ~= "number" then
		return zone
	end
	for i = 1, total do
		local ok, name, _, _, level, _, mZone, _, _, online, _, class = pcall(GetGuildRosterInfo, i)
		name, mZone = ok and Str(name), ok and Str(mZone)
		if name and mZone == zone and not IsSecret(online) and online then
			-- sans le royaume : Ambiguate(…, "none") le garde dans le jeu moderne
			local short = name:match("^[^-]+")
			if short ~= me and not InMyGroup(short) then
				nFound = nFound + 1
				found[nFound] = name
				foundShort[nFound] = short
				foundLevel[nFound] = (not IsSecret(level) and type(level) == "number") and level or nil
				foundClass[nFound] = Str(class)
			end
		end
	end
	return zone
end

local function CanInviteNow()
	if not IsInGroup() then
		return true
	end
	local ok, can = pcall(C_PartyInfo.CanInvite)
	return ok and not IsSecret(can) and can
end

local function Invite(name)
	local t = invitedAt[name]
	if t and GetTime() - t < INVITE_COOLDOWN then
		return false
	end
	if not pcall(C_PartyInfo.InviteUnit, name) then
		return false
	end
	invitedAt[name] = GetTime()
	return true
end

---------------------------------------------------------------------------
-- Icône à droite de la bande (même médaillon que Gnomeregan)
---------------------------------------------------------------------------
local button = CreateFrame("Button", nil, M.border)
button:SetSize(20, 20)
button:SetPoint("LEFT", M.band, "RIGHT", 6, 0)
button:SetFrameLevel(M.border:GetFrameLevel() + 5)
do
	local ring = M.Circle(button, 20, BRONZE[1] + 0.15, BRONZE[2] + 0.15, BRONZE[3] + 0.1, 1, "ARTWORK", 0)
	ring:SetPoint("CENTER")
	local icon = button:CreateTexture(nil, "ARTWORK", nil, 1)
	icon:SetTexture(ICON)
	icon:SetSize(16, 16)
	icon:SetPoint("CENTER")
	local m = button:CreateMaskTexture()
	m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(icon)
	icon:AddMaskTexture(m)
	local hl = M.Circle(button, 20, 1, 1, 1, 0.25, "HIGHLIGHT", 0)
	hl:SetPoint("CENTER")
end
M.inviteButton = button

---------------------------------------------------------------------------
-- Liste (créée à la première ouverture)
---------------------------------------------------------------------------
local list, zoneLine, rows, moreText, allButton

local function Refresh()
	if not list or not list:IsShown() then
		return
	end
	local zone = Scan()
	zoneLine:SetText(zone or T.unknownZone)
	local canInvite = CanInviteNow()
	local now = GetTime()
	local pending = 0
	local shown = math.min(nFound, MAX_ROWS)
	for i = 1, MAX_ROWS do
		local row = rows[i]
		if i <= shown then
			local name = found[i]
			local c = foundClass[i] and RAID_CLASS_COLORS and RAID_CLASS_COLORS[foundClass[i]]
			local t = invitedAt[name]
			local done = t and now - t < INVITE_COOLDOWN
			row.name, row.short = name, foundShort[i]
			row.text:SetText(foundShort[i])
			if done then
				row.text:SetTextColor(0.5, 0.5, 0.5)
			elseif c then
				row.text:SetTextColor(c.r, c.g, c.b)
			else
				row.text:SetTextColor(1, 1, 1)
			end
			row.info:SetText(done and T.invited or (foundLevel[i] and tostring(foundLevel[i]) or ""))
			row:SetEnabled(canInvite and not done)
			row:Show()
		else
			row.name = nil
			row:Hide()
		end
	end
	for i = 1, nFound do
		local t = invitedAt[found[i]]
		if not (t and now - t < INVITE_COOLDOWN) then
			pending = pending + 1
		end
	end

	local y = TOP - shown * ROW_H
	moreText:ClearAllPoints()
	moreText:SetPoint("TOPLEFT", list, "TOPLEFT", 10, y)
	if nFound == 0 then
		moreText:SetText(T.none)
		moreText:Show()
		y = y - math.max(ROW_H, (moreText:GetStringHeight() or 0) + 4)
	elseif nFound > MAX_ROWS then
		moreText:SetText(format(T.more, nFound - MAX_ROWS))
		moreText:Show()
		y = y - math.max(ROW_H, (moreText:GetStringHeight() or 0) + 4)
	elseif not canInvite then
		moreText:SetText(T.notLeader)
		moreText:Show()
		y = y - math.max(ROW_H, (moreText:GetStringHeight() or 0) + 4)
	else
		moreText:Hide()
	end

	allButton:SetText(format(T.all, pending))
	allButton:SetEnabled(canInvite and pending > 0)
	allButton:ClearAllPoints()
	allButton:SetPoint("TOP", list, "TOP", 0, y - 4)
	list:SetHeight(-y + 34)
end

local function OnRowClick(row)
	if row.name and Invite(row.name) then
		GI:Print(format(T.sent, row.short))
	end
	Refresh()
end

local function OnAllClick()
	local n = 0
	for i = 1, nFound do
		if Invite(found[i]) then
			n = n + 1
		end
	end
	if n > 0 then
		GI:Print(format(T.sent, n == 1 and "1 compagnon" or (n .. " compagnons")))
	end
	Refresh()
end

local function CreateList()
	list = CreateFrame("Frame", nil, UIParent)
	list:SetSize(LIST_W, 80)
	list:SetPoint("TOPLEFT", button, "BOTTOMRIGHT", 2, -2)
	list:SetFrameStrata("DIALOG")
	list:SetClampedToScreen(true)
	list:EnableMouse(true)
	local bg = list:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.03, 0.025, 0.02, 0.92)
	M.Frame4(list, BRONZE[1], BRONZE[2], BRONZE[3], 1, 2)

	local title = list:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 10, -8)
	title:SetPoint("RIGHT", -24, 0)
	title:SetJustifyH("LEFT")
	title:SetWordWrap(false)
	title:SetText(T.title)
	zoneLine = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	zoneLine:SetPoint("TOPLEFT", 10, -25)
	zoneLine:SetPoint("RIGHT", -10, 0)
	zoneLine:SetJustifyH("LEFT")
	zoneLine:SetWordWrap(false)

	local close = CreateFrame("Button", nil, list, "UIPanelCloseButton")
	close:SetSize(22, 22)
	close:SetPoint("TOPRIGHT", 0, 0)

	rows = {}
	for i = 1, MAX_ROWS do
		local row = CreateFrame("Button", nil, list)
		row:SetSize(LIST_W - 20, ROW_H)
		row:SetPoint("TOPLEFT", list, "TOPLEFT", 10, TOP - (i - 1) * ROW_H)
		row.info = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.info:SetPoint("RIGHT")
		row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.text:SetPoint("LEFT")
		row.text:SetPoint("RIGHT", row.info, "LEFT", -6, 0)
		row.text:SetJustifyH("LEFT")
		row.text:SetWordWrap(false)
		local hl = row:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 0.82, 0.3, 0.15)
		row:SetScript("OnClick", OnRowClick)
		rows[i] = row
	end
	moreText = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	moreText:SetWidth(LIST_W - 20)
	moreText:SetJustifyH("LEFT")

	allButton = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
	allButton:SetSize(150, 22)
	allButton:SetScript("OnClick", OnAllClick)
	list.all = allButton
	M.inviteList = list

	list:SetScript("OnShow", function()
		M:RegisterEvent("GUILD_ROSTER_UPDATE")
		if C_GuildInfo and C_GuildInfo.GuildRoster then
			C_GuildInfo.GuildRoster() -- demande au serveur une liste à jour
		end
	end)
	list:SetScript("OnHide", function()
		M:UnregisterEvent("GUILD_ROSTER_UPDATE")
	end)
	list:Hide()
end

function M:GUILD_ROSTER_UPDATE()
	Refresh()
end
M.RefreshInvites = Refresh -- appelé par la bande quand le groupe change

button:SetScript("OnClick", function()
	if not IsInGuild() then
		GI:Print(T.noGuild)
		return
	end
	if not list then
		CreateList()
	end
	list:SetShown(not list:IsShown())
	Refresh()
end)

button:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(T.title)
	GameTooltip:AddLine(IsInGuild() and T.hint or T.noGuild, 1, 1, 1, true)
	GameTooltip:Show()
end)
button:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

-- Appelé par ApplySettings
function M.ApplyInvite()
	button:SetShown(M.db.showInvite)
	if not M.db.showInvite and list then
		list:Hide()
	end
end
