--[[
  Test de fumée : charge l'addon hors du jeu avec une imitation minimale de l'API WoW,
  simule le chargement et quelques images. Attrape les erreurs de chargement et d'exécution
  grossières ; ne remplace PAS un test en jeu.
  Lancer depuis la racine du dépôt : lua5.1 tests/smoke.lua
]]

local ADDON = "GnomeraganIndependant"
local DIR = ADDON .. "/"

-- Objet « fourre-tout » : toute méthode inconnue existe et ne fait rien
local function Stub(extra)
	local o = extra or {}
	return setmetatable(o, {
		__index = function()
			return function()
				return nil
			end
		end,
	})
end

local frames = {}
local function NewFrame(_, name)
	local f = { scripts = {}, shown = true, w = 300, h = 26, alpha = 1, events = {} }
	function f:SetScript(k, fn)
		self.scripts[k] = fn
	end
	function f:GetScript(k)
		return self.scripts[k]
	end
	function f:Show()
		self.shown = true
	end
	function f:Hide()
		self.shown = false
	end
	function f:SetShown(v)
		self.shown = v and true or false
	end
	function f:IsShown()
		return self.shown
	end
	function f:SetSize(w, h)
		self.w, self.h = w, h
	end
	function f:SetWidth(w)
		self.w = w
	end
	function f:SetHeight(h)
		self.h = h
	end
	function f:GetWidth()
		return self.w
	end
	function f:GetHeight()
		return self.h
	end
	function f:GetFrameLevel()
		return 1
	end
	function f:GetAlpha()
		return self.alpha
	end
	function f:SetAlpha(a)
		self.alpha = a
	end
	function f:GetPoint()
		return "TOP", nil, "TOP", 0, -120
	end
	function f:RegisterEvent(e)
		self.events[e] = true
	end
	function f:UnregisterEvent(e)
		self.events[e] = nil
	end
	function f:CreateTexture()
		return NewFrame()
	end
	f.CreateMaskTexture = f.CreateTexture
	f.CreateFontString = f.CreateTexture
	f.CreateLine = f.CreateTexture
	f.GetThumbTexture = f.CreateTexture
	f = Stub(f)
	frames[#frames + 1] = f
	if name then
		_G[name] = f
	end
	return f
end

-- API imitée
CreateFrame = NewFrame
UIParent = NewFrame()
Minimap = NewFrame()
GameTooltip = NewFrame()
local chatLog = {}
DEFAULT_CHAT_FRAME = Stub({
	AddMessage = function(_, m)
		chatLog[#chatLog + 1] = m
		print("[chat] " .. m)
	end,
})
GameFontNormal = Stub({
	GetFont = function()
		return "Fonts\\FRIZQT__.TTF", 12
	end,
})
SlashCmdList = {}
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
C_AddOns = {
	GetAddOnMetadata = function()
		return "dev"
	end,
}
EventRegistry = Stub()
wipe = function(t)
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end
date = os.date
GetTime = os.clock
GetLocale = function()
	return "frFR"
end
issecretvalue = function()
	return false
end
GetPlayerFacing = function()
	return 1.2
end
local px, py, pinst = -5000, -400, 0
UnitPosition = function(u)
	if u == "player" then
		return px, py, 0, pinst
	elseif u == "party1" then
		return px + 30, py - 20, 0, pinst
	end
end
UnitExists = function(u)
	return u == "party1" or u == "target"
end
UnitIsUnit = function(a, b)
	return a == b or (a == "party1" and b == "target")
end
UnitGUID = function(u)
	return "Player-" .. u
end
UnitName = function(u)
	return u == "party1" and "Pierre" or "Moi"
end
UnitClass = function()
	return "Mage", "MAGE"
end
UnitIsDeadOrGhost = function()
	return false
end
UnitGroupRolesAssigned = function()
	return "HEALER"
end
GetRaidTargetIndex = function()
	return 8
end
IsInRaid = function()
	return false
end
IsInGroup = function()
	return true
end
GetNumSubgroupMembers = function()
	return 1
end
GetNumGroupMembers = function()
	return 2
end
GetGameTime = function()
	return 21, 30
end
GetZoneText = function()
	return "Dun Morogh"
end
CreateVector2D = function(x, y)
	return { x = x, y = y }
end
-- Dun Morogh imitée : une carte de 6000 m sur 4000 m sur le continent 0
C_Map = {
	GetBestMapForUnit = function()
		return 1426
	end,
	-- 1426 = Dun Morogh (continent 0), 1440 = zone de Kalimdor (continent 1), à l'ouest sur Azeroth
	GetWorldPosFromMapPos = function(map, v)
		return map == 1426 and 0 or 1, { x = -3000 - 4000 * v.y, y = 1500 - 6000 * v.x }
	end,
	GetMapRectOnMap = function(map)
		if map == 1426 then
			return 0.7, 0.75, 0.5, 0.55
		end
		return 0.1, 0.2, 0.45, 0.6
	end,
	-- repère de carte : dans Forever, position est une table simple { x, y } sans GetXY
	HasUserWaypoint = function()
		return true
	end,
	GetUserWaypoint = function()
		return { uiMapID = 1426, position = { x = 0.3, y = 0.4 } }
	end,
}
C_SuperTrack = {
	GetSuperTrackedQuestID = function()
		return 0
	end,
}
C_QuestLog = {}

-- Guilde : Pierre est déjà dans le groupe, Paul ailleurs, Jacques hors ligne ; Lise et Marc invitables
local guild = {
	{ "Moi-Royaume", "Dun Morogh", true },
	{ "Pierre-Royaume", "Dun Morogh", true },
	{ "Lise-Royaume", "Dun Morogh", true },
	{ "Marc-Royaume", "Dun Morogh", true },
	{ "Paul-Royaume", "Durotar", true },
	{ "Jacques-Royaume", "Dun Morogh", false },
}
local invites = {}
IsInGuild = function()
	return true
end
GetNumGuildMembers = function()
	return #guild, #guild
end
GetGuildRosterInfo = function(i)
	local g = guild[i]
	return g[1], "Membre", 1, 25, "Mage", g[2], "", "", g[3], 0, "MAGE"
end
GetRealZoneText = function()
	return "Dun Morogh"
end
-- comme dans le jeu moderne avec "none" : le royaume reste
Ambiguate = function(name)
	return name
end
UnitInParty = function(name)
	return name == "Pierre"
end
UnitInRaid = function()
	return nil
end
C_GuildInfo = { GuildRoster = function() end }
C_PartyInfo = {
	CanInvite = function()
		return true
	end,
	InviteUnit = function(name)
		invites[#invites + 1] = name
	end,
}

-- Chargement dans l'ordre du .toc
local ns = {}
local toc = assert(io.open(DIR .. ADDON .. ".toc"))
for line in toc:lines() do
	line = line:gsub("\r", "")
	if line ~= "" and not line:match("^##") then
		local path = DIR .. line:gsub("\\", "/")
		local chunk = assert(loadfile(path))
		chunk(ADDON, ns)
	end
end
toc:close()

-- Chargement de l'addon, puis entrée dans le monde
for _, f in ipairs(frames) do
	local fn = f.scripts.OnEvent
	if fn and f.events.ADDON_LOADED then
		fn(f, "ADDON_LOADED", ADDON)
	end
end
assert(GnomeraganIndependantDB and GnomeraganIndependantDB.modules.Boussole, "réglages non créés")
for _, f in ipairs(frames) do
	local fn = f.scripts.OnEvent
	if fn then
		fn(f, "PLAYER_ENTERING_WORLD")
		-- ping d'un membre : identifié par son GUID (12e argument)
		fn(f, "CHAT_MSG_PING", "Attaque", "Pierre-Royaume", "", "", "", "", 0, 0, "", 0, 1, "Player-party1")
	end
end

-- Quelques images de boussole, en tournant et en marchant
local band = assert(_G.GnomeraganBoussole, "bande absente")
assert(band:IsShown(), "bande masquée")
local onUpdate = assert(band.scripts.OnUpdate)
for i = 1, 200 do
	px = px + 1
	onUpdate(band, 1 / 60)
	if i == 100 then
		GetPlayerFacing = function()
			return 4
		end
	end
end

-- Invitations : ouvrir la liste, inviter tous, puis un second clic ne réinvite personne
local M0 = ns.modules.Boussole
M0.inviteButton.scripts.OnClick(M0.inviteButton)
assert(M0.inviteList:IsShown(), "liste d'invitation fermée")
M0.inviteList.all.scripts.OnClick(M0.inviteList.all)
M0.inviteList.all.scripts.OnClick(M0.inviteList.all)
assert(table.concat(invites, ",") == "Lise-Royaume,Marc-Royaume", "invitations : " .. table.concat(invites, ","))

for i = 1, #chatLog do
	assert(not chatLog[i]:find("erreur"), "erreur signalée : " .. chatLog[i])
end

-- Commandes
SlashCmdList.GNOMERAGAN("")
SlashCmdList.GIBOUSSOLE("loc")
SlashCmdList.GIBOUSSOLE("diag")
SlashCmdList.GIBOUSSOLE("options")
SlashCmdList.GIBOUSSOLE("reset")
SlashCmdList.GIBOUSSOLE("")
assert(GnomeraganIndependantDB.modules.Boussole.shown == false, "bascule sans effet")

local M = ns.modules.Boussole
M.RefreshHome()
assert(M.homeMode == "near", "Gnomeregan devrait être sur le même continent")

-- Sur Kalimdor : direction approximative, vers l'est
-- (l'addon garde UnitPosition en local : on change le continent, pas la fonction)
px, py, pinst = -4800, -400, 1
C_Map.GetBestMapForUnit = function()
	return 1440
end
M.UpdateCurrentMap()
M.UpdatePlayerWorld()
M.RefreshHome()
assert(M.homeMode == "far", "Gnomeregan devrait être outre-mer")
assert(M.homeBearing > 45 and M.homeBearing < 135, "devrait pointer vers l'est : " .. tostring(M.homeBearing))
print(string.format("Gnomeregan depuis Kalimdor : %.0f°", M.homeBearing))
print("OK : chargement, 200 images, commandes et Gnomeregan sans erreur")
