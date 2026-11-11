--[[
  Gnomeragan Indépendant — cœur de l'addon.
  Espace de noms GI, base sauvegardée, distribution des événements, registre de modules.

  Un module se déclare ainsi :
    local _, GI = ...
    local M = GI:NewModule("Boussole", { shown = true })   -- 2e argument : réglages par défaut
    function M:OnEnable() self:RegisterEvent("PLAYER_TARGET_CHANGED") end
    function M:PLAYER_TARGET_CHANGED() ... end
  Les réglages du module sont dans M.db (GnomeraganIndependantDB.modules.Boussole).
]]

local ADDON, GI = ...

GI.name = ADDON
GI.version = C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "dev"

---------------------------------------------------------------------------
-- Utilitaires
---------------------------------------------------------------------------
local issecretvalue = issecretvalue

-- Toujours tester AVANT de comparer une valeur venant du jeu
function GI.IsSecret(v)
	return issecretvalue ~= nil and issecretvalue(v)
end

function GI:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff3fa0ffGnomeragan|r : " .. tostring(msg))
end

local function CopyDefaults(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then
				dst[k] = {}
			end
			CopyDefaults(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

---------------------------------------------------------------------------
-- Événements : un seul cadre, distribué aux modules abonnés
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local listeners = {} -- [event] = { module, ... }

local function Dispatch(_, event, ...)
	local list = listeners[event]
	if not list then
		return
	end
	for i = 1, #list do
		local m = list[i]
		m[event](m, ...)
	end
end
frame:SetScript("OnEvent", Dispatch)

local Module = {}
Module.__index = Module

function Module:RegisterEvent(event)
	local list = listeners[event]
	if not list then
		list = {}
		listeners[event] = list
		-- certains événements peuvent ne pas exister dans ce client
		if not pcall(frame.RegisterEvent, frame, event) then
			listeners[event] = nil
			return false
		end
	end
	for i = 1, #list do
		if list[i] == self then
			return true
		end
	end
	list[#list + 1] = self
	return true
end

function Module:UnregisterEvent(event)
	local list = listeners[event]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		if list[i] == self then
			table.remove(list, i)
		end
	end
	if #list == 0 then
		listeners[event] = nil
		frame:UnregisterEvent(event)
	end
end

---------------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------------
GI.modules = {}
local order = {}

function GI:NewModule(name, defaults)
	assert(not self.modules[name], "module déjà déclaré : " .. name)
	local m = setmetatable({ name = name, defaults = defaults or {} }, Module)
	self.modules[name] = m
	order[#order + 1] = m
	return m
end

---------------------------------------------------------------------------
-- Chargement
---------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON then
		return
	end
	self:UnregisterEvent("ADDON_LOADED")

	GnomeraganIndependantDB = GnomeraganIndependantDB or {}
	local db = GnomeraganIndependantDB
	db.modules = db.modules or {}
	GI.db = db

	for i = 1, #order do
		local m = order[i]
		db.modules[m.name] = db.modules[m.name] or {}
		m.db = db.modules[m.name]
		CopyDefaults(m.db, m.defaults)
		if m.OnEnable then
			local ok, err = pcall(m.OnEnable, m)
			if not ok then
				GI:Print("erreur au démarrage du module " .. m.name .. " : " .. tostring(err))
			end
		end
	end
end)

---------------------------------------------------------------------------
-- Commande /gi
---------------------------------------------------------------------------
SLASH_GNOMERAGAN1 = "/gi"
SLASH_GNOMERAGAN2 = "/gnomeragan"
SlashCmdList.GNOMERAGAN = function(msg)
	local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
	cmd = cmd:lower()
	for i = 1, #order do
		local m = order[i]
		if m.slash and m.slash == cmd and m.OnSlash then
			return m:OnSlash(rest)
		end
	end
	GI:Print("version " .. tostring(GI.version) .. ". Modules :")
	for i = 1, #order do
		local m = order[i]
		GI:Print("  " .. m.name .. (m.slash and (" — /gi " .. m.slash) or ""))
	end
end
