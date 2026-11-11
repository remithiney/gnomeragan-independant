--[[
  Boussole — déclaration du module, réglages par défaut et géométrie.

  Monde WoW : 1re valeur de UnitPosition = axe nord, 2e = axe ouest.
  GetPlayerFacing : 0 = nord, sens anti-horaire. Les caps sont ici en degrés, sens horaire depuis le nord.
  Limite Blizzard : en instance et en champ de bataille, ni cap ni positions pour les addons.
]]

local _, GI = ...

local M = GI:NewModule("Boussole", {
	shown = true,
	locked = true,
	fps = 30, -- rafraîchissements par seconde (petites configs : 20)
	fov = 180,
	width = 300,
	height = 26,
	scale = 1,
	alpha = 1,
	bgAlpha = 0.35,
	dirSize = 15,
	showDegrees = true,
	celest = true,
	-- textes sous la bande
	showHeading = true,
	showCoords = false,
	showDist = true,
	showZone = false,
	-- marqueurs
	showHome = true, -- direction de Gnomeregan
	showParty = true,
	showRaid = false, -- sinon, en raid : seulement mon sous-groupe
	raidIcons = true,
	healers = true,
	showTarget = true,
	showPings = true,
	showWaypoint = true,
	showQuest = true,
	showEdges = true,
	range = 0, -- portée max des membres en mètres (0 = illimitée)
	markerSize = 10,
})
M.slash = "boussole"

local RAD2DEG = 180 / math.pi
local atan2, sqrt, floor = math.atan2, math.sqrt, math.floor
local IsSecret = GI.IsSecret
local UnitPosition = UnitPosition

M.DIRS = { "N", "NE", "E", "SE", "S", "SO", "O", "NO" }

function M.DirName(h)
	return M.DIRS[floor((h + 22.5) / 45) % 8 + 1]
end

-- Écart signé entre deux caps, dans [-180, 180[
function M.Delta(h, ref)
	return ((h - ref + 540) % 360) - 180
end
local Delta = M.Delta

---------------------------------------------------------------------------
-- Cap et position du joueur (M.pN = nil si inconnue)
---------------------------------------------------------------------------
function M.GetHeading()
	local ok, f = pcall(GetPlayerFacing)
	if not ok or IsSecret(f) or not f then
		return nil
	end
	return (360 - f * RAD2DEG) % 360
end

function M.UpdatePlayerWorld()
	local n, w, _, inst = UnitPosition("player")
	if IsSecret(n) or not n then
		M.pN = nil
		return
	end
	M.pN, M.pW, M.pInst = n, w, inst
end

function M.BearingTo(n, w)
	local dN, dW = n - M.pN, w - M.pW
	return (360 - atan2(dW, dN) * RAD2DEG) % 360, sqrt(dN * dN + dW * dW)
end

-- Lissage angulaire : supprime le tremblement de près, reste réactif de loin
function M.Smooth(prev, target, dt, dist)
	if not prev then
		return target
	end
	if dist and dist < 1.5 then
		return prev
	end
	local k = 30
	if dist and dist < 15 then
		k = 4 + 26 * (dist / 15)
	end
	local a = 1 - 2.718281828 ^ (-k * dt)
	return (prev + Delta(target, prev) * a) % 360
end

---------------------------------------------------------------------------
-- Cartes : conversion coordonnées de carte (0-1) -> monde, en cache par carte
---------------------------------------------------------------------------
local transforms = {}

local function GetTransform(mapID)
	local t = transforms[mapID]
	if t == nil then
		t = false
		if CreateVector2D then
			local ok1, c1, a = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(0, 0))
			local ok2, c2, b = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(1, 1))
			if ok1 and ok2 and c1 and a and b and c1 == c2 then
				t = { c1, a.x, a.y, b.x - a.x, b.y - a.y }
			end
		end
		transforms[mapID] = t
	end
	return t or nil
end

function M.ClearMapCache()
	wipe(transforms)
end

function M.MapToWorld(mapID, x, y)
	local t = GetTransform(mapID)
	if not t then
		return nil
	end
	return t[2] + t[4] * y, t[3] + t[5] * x, t[1]
end

function M.UpdateCurrentMap()
	M.curMap = C_Map.GetBestMapForUnit("player")
end

-- Coordonnées 0-1 du joueur sur sa carte, depuis sa position monde (aucune table créée)
function M.PlayerMapFrac()
	local map = M.curMap
	if not M.pN or not map then
		return nil
	end
	local t = GetTransform(map)
	if not t or t[1] ~= M.pInst or t[4] == 0 or t[5] == 0 then
		return nil
	end
	local x, y = (M.pW - t[3]) / t[5], (M.pN - t[2]) / t[4]
	if x < 0 or x > 1 or y < 0 or y > 1 then
		return nil
	end
	return x, y
end

---------------------------------------------------------------------------
-- Gnomeregan : direction exacte sur le même continent, approximative ailleurs
-- (via la carte d'Azeroth, comme une qibla).
-- Relevé en jeu devant l'entrée (/boussole loc, 2026-11-11) : carte 1426 = Dun Morogh,
-- 24.3, 39.7 ; monde -5182.1 / 604.3, continent 0.
---------------------------------------------------------------------------
local HOME_MAP, HOME_X, HOME_Y = 1426, 0.243, 0.397 -- pour la carte d'Azeroth (autres continents)
local HOME_N, HOME_W, HOME_INST = -5182.1, 604.3, 0 -- position monde exacte (même continent)
local AZEROTH = 947

local homeReady, homeN, homeW, homeInst
local homeAzX, homeAzY, azAspect = nil, nil, 1
local azRects = {} -- [mapID] = { minX, maxX, minY, maxY } sur la carte d'Azeroth, ou false

local function AzRect(mapID)
	local r = azRects[mapID]
	if r == nil then
		r = false
		if C_Map.GetMapRectOnMap then
			local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, mapID, AZEROTH)
			if ok and minX and maxX and maxX > minX and maxY > minY then
				r = { minX, maxX, minY, maxY }
			end
		end
		azRects[mapID] = r
	end
	return r or nil
end

local function InitHome()
	homeReady = true
	homeN, homeW, homeInst = HOME_N, HOME_W, HOME_INST
	local r = AzRect(HOME_MAP)
	if r then
		homeAzX = r[1] + (r[2] - r[1]) * HOME_X
		homeAzY = r[3] + (r[4] - r[3]) * HOME_Y
		-- la carte d'Azeroth n'est pas carrée : rapport mètres par unité en x / en y
		local t = GetTransform(HOME_MAP)
		if t and t[4] ~= 0 and t[5] ~= 0 then
			azAspect = (math.abs(t[5]) / (r[2] - r[1])) / (math.abs(t[4]) / (r[4] - r[3]))
		end
	end
end

-- Met à jour M.homeMode : "near" (M.homeN, M.homeW), "far" (M.homeBearing) ou nil
function M.RefreshHome()
	M.homeMode = nil
	if not M.pN then
		return
	end
	if not homeReady then
		InitHome()
	end
	if homeN and homeInst == M.pInst then
		M.homeMode, M.homeN, M.homeW = "near", homeN, homeW
		return
	end
	if not homeAzX or not M.curMap then
		return
	end
	local r = AzRect(M.curMap)
	local x, y = M.PlayerMapFrac()
	if not r or not x then
		return
	end
	local dx = (homeAzX - (r[1] + (r[2] - r[1]) * x)) * azAspect
	local dy = homeAzY - (r[3] + (r[4] - r[3]) * y)
	if dx ~= 0 or dy ~= 0 then
		M.homeMode, M.homeBearing = "far", (atan2(dx, -dy) * RAD2DEG) % 360
	end
end
