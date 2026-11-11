--[[
  Boussole — la bande, les marqueurs et la boucle d'affichage.
  Rafraîchie db.fps fois par seconde, seulement quand elle est visible.
]]

local _, GI = ...
local M = GI.modules.Boussole

local PI = math.pi
local sin = math.sin
local floor, abs, min, max = math.floor, math.abs, math.min, math.max
local format = string.format
local GetTime, UnitPosition, UnitExists, UnitIsUnit, UnitGUID = GetTime, UnitPosition, UnitExists, UnitIsUnit, UnitGUID
local IsSecret, Delta, DirName, BearingTo, Smooth = GI.IsSecret, M.Delta, M.DirName, M.BearingTo, M.Smooth

local MIN_W, MIN_H, MAX_W, MAX_H = 120, 16, 1000, 64
local PING_DURATION = 5
local RAID_ICON_PATH = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
local HOME_ICON = "Interface\\Icons\\Trade_Engineering"
local BRONZE = { 0.66, 0.51, 0.24 }
M.BRONZE = BRONZE

local db -- réglages du module, donnés au démarrage

local function SafeBool(v)
	if IsSecret(v) then
		return false
	end
	return v and true or false
end

---------------------------------------------------------------------------
-- Groupe : unités suivies, couleur de classe, rôle, icône de raid
---------------------------------------------------------------------------
local PARTY_UNITS, RAID_UNITS = {}, {}
for i = 1, 4 do
	PARTY_UNITS[i] = "party" .. i
end
for i = 1, 40 do
	RAID_UNITS[i] = "raid" .. i
end

local units = {} -- unités affichées
local unitGUID = {} -- [unit] = GUID, pour garder le lissage si le jeton désigne toujours le même joueur
local memberSmooth = {} -- [unit] = cap lissé
local unitInfo = {} -- [unit] = { r, g, b, healer, icon, ver }
local infoVersion = 0
local targetUnit, tSmooth

local function FillInfo(u)
	local info = unitInfo[u]
	if not info then
		info = {}
		unitInfo[u] = info
	end
	local _, cls = UnitClass(u)
	local c = not IsSecret(cls) and cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
	if c then
		info.r, info.g, info.b = c.r, c.g, c.b
	else
		info.r, info.g, info.b = 0.8, 0.8, 0.8
	end
	local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(u)
	info.healer = not IsSecret(role) and role == "HEALER"
	local icon = GetRaidTargetIndex(u)
	if IsSecret(icon) then
		icon = nil
	end
	info.icon = icon
	infoVersion = infoVersion + 1
	info.ver = infoVersion
end

local function FindTargetUnit()
	local found
	if UnitExists("target") and not SafeBool(UnitIsUnit("target", "player")) then
		local list, n
		if IsInRaid() then
			list, n = RAID_UNITS, GetNumGroupMembers()
		else
			list, n = PARTY_UNITS, GetNumSubgroupMembers()
		end
		for i = 1, min(n, #list) do
			if SafeBool(UnitIsUnit(list[i], "target")) then
				found = list[i]
				break
			end
		end
	end
	if found ~= targetUnit then
		targetUnit, tSmooth = found, nil
	end
	if M.debug and UnitExists("target") then
		GI:Print(
			"[diag] cible : " .. (found and ("membre du groupe (" .. found .. ")") or "hors groupe, non affichée")
		)
	end
end

local function RebuildRoster()
	wipe(units)
	if IsInRaid() then
		local n = min(GetNumGroupMembers(), 40)
		local mySub
		for i = 1, n do
			if SafeBool(UnitIsUnit(RAID_UNITS[i], "player")) then
				local _, _, sub = GetRaidRosterInfo(i)
				mySub = sub
				break
			end
		end
		for i = 1, n do
			local u = RAID_UNITS[i]
			if not SafeBool(UnitIsUnit(u, "player")) then
				local _, _, sub = GetRaidRosterInfo(i)
				if db.showRaid or sub == mySub then
					units[#units + 1] = u
				end
			end
		end
	elseif IsInGroup() then
		for i = 1, min(GetNumSubgroupMembers(), 4) do
			units[#units + 1] = PARTY_UNITS[i]
		end
	end
	for i = 1, #units do
		local u = units[i]
		local g = UnitGUID(u)
		if IsSecret(g) then
			g = nil
		end
		if g == nil or unitGUID[u] ~= g then
			memberSmooth[u] = nil
		end
		unitGUID[u] = g
		FillInfo(u)
	end
	FindTargetUnit()
end
M.RebuildRoster = RebuildRoster

-- Icônes de raid ou rôles changés : inutile de reconstruire la liste
local function RefreshInfo()
	for i = 1, #units do
		FillInfo(units[i])
	end
end

---------------------------------------------------------------------------
-- Objectifs : repère de carte, quête suivie, Gnomeregan (rafraîchis toutes les 2 s)
---------------------------------------------------------------------------
local wpN, wpW, qN, qW

local function RefreshObjectives()
	wpN, qN = nil, nil
	M.RefreshHome()
	if not M.pN then
		return
	end
	local pInst = M.pInst

	if db.showWaypoint and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint() then
		local p = C_Map.GetUserWaypoint()
		local pos = type(p) == "table" and p.position
		-- Forever : position est parfois une table simple { x, y } sans GetXY (vu au wipe, 2026-11-11)
		local x, y
		if type(pos) == "table" then
			x, y = pos.x, pos.y
		end
		if type(x) == "number" and type(y) == "number" and type(p.uiMapID) == "number" then
			local n, w, inst = M.MapToWorld(p.uiMapID, x, y)
			if n and inst == pInst then
				wpN, wpW = n, w
			end
		end
	end

	if db.showQuest and C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
		local qid = C_SuperTrack.GetSuperTrackedQuestID()
		if qid and qid > 0 then
			local mapID, x, y
			if C_QuestLog.GetNextWaypoint then
				mapID, x, y = C_QuestLog.GetNextWaypoint(qid)
			end
			if not (mapID and x and y) then
				mapID, x, y = M.curMap, nil, nil
				if mapID then
					-- protégés : ForeverAPI signale des erreurs selon les arguments
					if C_TaskQuest and C_TaskQuest.GetQuestLocation then
						local ok, a, b = pcall(C_TaskQuest.GetQuestLocation, qid, mapID)
						if ok then
							x, y = a, b
						end
					end
					if not x and C_QuestLog.GetQuestsOnMap then
						local ok, list = pcall(C_QuestLog.GetQuestsOnMap, mapID)
						if ok and type(list) == "table" then
							for i = 1, #list do
								if list[i].questID == qid then
									x, y = list[i].x, list[i].y
									break
								end
							end
						end
					end
				end
			end
			if mapID and x and y then
				local n, w, inst = M.MapToWorld(mapID, x, y)
				if n and inst == pInst then
					qN, qW = n, w
				end
			end
		end
	end
end

-- Pings : WoW Forever ne donne ni MINIMAP_PING ni la position des pings en jeu.
-- On sait seulement QUI a pingé (CHAT_MSG_PING) : son point clignote sur la bande.
local pingAt = {} -- [unit] = GetTime() du dernier ping

---------------------------------------------------------------------------
-- Briques graphiques
---------------------------------------------------------------------------
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local function Circle(parent, size, r, g, b, a, layer, sub)
	local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
	t:SetColorTexture(r, g, b, a)
	t:SetSize(size, size)
	local m = parent:CreateMaskTexture()
	m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(t)
	t:AddMaskTexture(m)
	return t
end
M.Circle = Circle

local FRAME4 = {
	{ "TOPLEFT", "TOPRIGHT", false },
	{ "BOTTOMLEFT", "BOTTOMRIGHT", false },
	{ "TOPLEFT", "BOTTOMLEFT", true },
	{ "TOPRIGHT", "BOTTOMRIGHT", true },
}
-- Bordure de 4 traits autour d'un cadre
function M.Frame4(parent, r, g, b, a, thick)
	for _, spec in ipairs(FRAME4) do
		local t = parent:CreateTexture(nil, "BORDER")
		t:SetColorTexture(r, g, b, a)
		t:SetPoint(spec[1], parent, spec[1])
		t:SetPoint(spec[2], parent, spec[2])
		if spec[3] then
			t:SetWidth(thick)
		else
			t:SetHeight(thick)
		end
	end
end

---------------------------------------------------------------------------
-- Bande
---------------------------------------------------------------------------
local band = CreateFrame("Frame", "GnomeraganBoussole", UIParent)
band:SetSize(300, 26)
band:SetPoint("TOP", UIParent, "TOP", 0, -120)
band:SetMovable(true)
band:SetResizable(true)
band:SetClampedToScreen(true)
if band.SetResizeBounds then
	band:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
elseif band.SetMinResize then
	band:SetMinResize(MIN_W, MIN_H)
	band:SetMaxResize(MAX_W, MAX_H)
end
if band.SetClipsChildren then
	band:SetClipsChildren(true)
end
band:Hide()
M.band = band

local bg = band:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.03, 0.025, 0.02, 1)

-- Cadre frère, non coupé par le clipping : bordure, index, marqueurs, textes
local border = CreateFrame("Frame", nil, UIParent)
border:SetPoint("TOPLEFT", band, "TOPLEFT", -2, 2)
border:SetPoint("BOTTOMRIGHT", band, "BOTTOMRIGHT", 2, -2)
border:SetFrameLevel(band:GetFrameLevel() + 3)
border:Hide()
M.Frame4(border, BRONZE[1], BRONZE[2], BRONZE[3], 1, 2)
M.border = border

local centerMark = border:CreateTexture(nil, "OVERLAY")
centerMark:SetColorTexture(1, 0.82, 0.3, 1)
centerMark:SetWidth(2)
centerMark:SetPoint("TOP", band, "TOP", 0, 3)
centerMark:SetPoint("BOTTOM", band, "BOTTOM", 0, -3)

local ticks = {}
for h = 0, 355, 5 do
	local kind = (h % 45 == 0) and 3 or ((h % 15 == 0) and 2 or 1)
	local l = band:CreateLine(nil, "ARTWORK")
	l:SetThickness(kind == 3 and 2 or 1)
	l:SetColorTexture(0.85, 0.75, 0.5, 1)
	ticks[#ticks + 1] = { h = h, kind = kind, line = l }
end

local FONT = (GameFontNormal and GameFontNormal:GetFont()) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local labels = {}
for i = 1, 8 do
	local cardinal = (i % 2 == 1)
	local fs = band:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetText(M.DIRS[i])
	if i == 1 then
		fs:SetTextColor(1, 0.22, 0.18)
	elseif cardinal then
		fs:SetTextColor(1, 0.93, 0.7)
	else
		fs:SetTextColor(0.85, 0.8, 0.65)
	end
	labels[#labels + 1] = { h = (i - 1) * 45, fs = fs, cardinal = cardinal }
end
for h = 15, 345, 15 do
	if h % 45 ~= 0 then
		local fs = band:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		fs:SetText(h)
		fs:SetTextColor(0.7, 0.7, 0.7)
		labels[#labels + 1] = { h = h, fs = fs, small = true }
	end
end

local fontSize
local function ApplyFonts()
	if fontSize == db.dirSize then
		return
	end
	fontSize = db.dirSize
	for i = 1, #labels do
		local lb = labels[i]
		if lb.small then
			lb.fs:SetFont(FONT, max(7, floor(fontSize * 0.55 + 0.5)), "")
		else
			lb.fs:SetFont(FONT, lb.cardinal and fontSize or max(8, floor(fontSize * 0.72 + 0.5)), "OUTLINE")
		end
	end
end

local unknownText = border:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
unknownText:SetPoint("CENTER", band, "CENTER")
unknownText:SetText("Cap indisponible (zone protégée)")
unknownText:Hide()

-- Graduations : refaites seulement si le cap (arrondi au pixel) ou la taille change
local lastRef, lastW, lastH, lastHalf, lastDim

local function LayoutScale(ref, W, H, half, span, dim)
	if ref == lastRef and W == lastW and H == lastH and half == lastHalf and dim == lastDim then
		return
	end
	lastRef, lastW, lastH, lastHalf, lastDim = ref, W, H, half, dim
	local k = H / 26

	for i = 1, #ticks do
		local t = ticks[i]
		local d = Delta(t.h, ref)
		if abs(d) <= half then
			local x = d / half * span
			local len = (t.kind == 3 and 7 or (t.kind == 2 and 5 or 3)) * k
			t.line:SetStartPoint("BOTTOM", band, x, 2)
			t.line:SetEndPoint("BOTTOM", band, x, 2 + len)
			t.line:SetAlpha((t.kind == 1 and 0.5 or 0.85) * (1 - (abs(d) / half) ^ 2 * 0.75) * dim)
			t.line:Show()
		else
			t.line:Hide()
		end
	end

	local edge = half * (1 - 8 / max(span, 1))
	local smallFits = db.showDegrees and (span / half * 15 >= 22)
	for i = 1, #labels do
		local lb = labels[i]
		local d = Delta(lb.h, ref)
		if (smallFits or not lb.small) and abs(d) <= edge then
			lb.fs:SetPoint("CENTER", band, "CENTER", d / half * span, lb.small and 5 * k or 2 * k)
			local fall = (abs(d) / half) ^ 2
			lb.fs:SetAlpha((lb.small and 0.45 * (1 - fall * 0.8) or (1 - fall * 0.55)) * dim)
			lb.fs:Show()
		else
			lb.fs:Hide()
		end
	end
end

---------------------------------------------------------------------------
-- Marqueurs
---------------------------------------------------------------------------
local styleVersion = 0 -- augmente quand la taille ou les options d'affichage changent

-- Membre : halo blanc (soignant), contour, couleur de classe, icône de raid
local function NewMember()
	local m = CreateFrame("Frame", nil, border)
	m:SetFrameLevel(border:GetFrameLevel() + 4)
	m.halo = Circle(m, 1, 1, 1, 1, 0.95, "ARTWORK", 0)
	m.edge = Circle(m, 1, 0, 0, 0, 1, "ARTWORK", 1)
	m.fill = Circle(m, 1, 1, 1, 1, 1, "ARTWORK", 2)
	m.icon = m:CreateTexture(nil, "OVERLAY")
	m.ping = Circle(m, 1, 1, 0.6, 0.1, 1, "BACKGROUND", 0) -- anneau de ping, pulsant
	m.ping:SetPoint("CENTER")
	m.ping:Hide()
	m.halo:SetPoint("CENTER")
	m.edge:SetPoint("CENTER")
	m.fill:SetPoint("CENTER")
	m.icon:SetPoint("CENTER")
	m:Hide()
	return m
end

local function StyleMember(m, info, dead)
	if m.sInfo == info and m.sVer == info.ver and m.sDead == dead and m.sStyle == styleVersion then
		return
	end
	m.sInfo, m.sVer, m.sDead, m.sStyle = info, info.ver, dead, styleVersion
	local s = db.markerSize
	m:SetSize(s + 6, s + 6)
	m.halo:SetSize(s + 5, s + 5)
	m.edge:SetSize(s + 2, s + 2)
	m.fill:SetSize(s, s)
	m.icon:SetSize(s + 5, s + 5)
	m.ping:SetSize(s + 12, s + 12)
	if dead then
		m.fill:SetColorTexture(0.4, 0.4, 0.4, 1)
	else
		m.fill:SetColorTexture(info.r, info.g, info.b, 1)
	end
	m.halo:SetShown(db.healers and info.healer and not dead)
	if db.raidIcons and info.icon then
		m.icon:SetTexture(RAID_ICON_PATH .. info.icon)
		m.icon:SetDesaturated(dead)
		m.icon:Show()
		m.fill:Hide()
		m.edge:Hide()
	else
		m.icon:Hide()
		m.fill:Show()
		m.edge:Show()
	end
end

local memberMarkers = {}
local function GetMember(i)
	local m = memberMarkers[i]
	if not m then
		m = NewMember()
		memberMarkers[i] = m
	end
	return m
end

-- Losange : cible, repère, quête
local function NewDiamond(r, g, b, er, eg, eb, scale)
	local m = CreateFrame("Frame", nil, border)
	m:SetFrameLevel(border:GetFrameLevel() + 6)
	m.edge = m:CreateTexture(nil, "OVERLAY", nil, 0)
	m.edge:SetColorTexture(er, eg, eb, 1)
	m.edge:SetPoint("CENTER")
	m.edge:SetRotation(PI / 4)
	m.fill = m:CreateTexture(nil, "OVERLAY", nil, 1)
	m.fill:SetColorTexture(r, g, b, 1)
	m.fill:SetPoint("CENTER")
	m.fill:SetRotation(PI / 4)
	m.scale = scale
	m:Hide()
	return m
end

local function SizeDiamond(m)
	if m.sStyle == styleVersion then
		return
	end
	m.sStyle = styleVersion
	local side = db.markerSize * m.scale * 0.72
	m:SetSize(side * 1.5 + 4, side * 1.5 + 4)
	m.edge:SetSize(side + 3, side + 3)
	m.fill:SetSize(side, side)
end

local targetMark = NewDiamond(1, 0.15, 0.1, 1, 1, 1, 1.35)
local wpMark = NewDiamond(0.25, 1, 0.35, 0, 0.15, 0, 1)
local questMark = NewDiamond(1, 0.85, 0.1, 0.25, 0.15, 0, 1)

-- Gnomeregan : médaillon rond, anneau de bronze, icône d'ingénierie
local homeMark = CreateFrame("Frame", nil, border)
homeMark:SetFrameLevel(border:GetFrameLevel() + 5)
homeMark.ring = Circle(homeMark, 1, BRONZE[1] + 0.15, BRONZE[2] + 0.15, BRONZE[3] + 0.1, 1, "ARTWORK", 0)
homeMark.ring:SetPoint("CENTER")
homeMark.icon = homeMark:CreateTexture(nil, "ARTWORK", nil, 1)
homeMark.icon:SetTexture(HOME_ICON)
homeMark.icon:SetPoint("CENTER")
do
	local m = homeMark:CreateMaskTexture()
	m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(homeMark.icon)
	homeMark.icon:AddMaskTexture(m)
end
homeMark:Hide()

local function SizeHome()
	if homeMark.sStyle == styleVersion then
		return
	end
	homeMark.sStyle = styleVersion
	local s = db.markerSize + 6
	homeMark:SetSize(s + 2, s + 2)
	homeMark.ring:SetSize(s + 2, s + 2)
	homeMark.icon:SetSize(s - 1, s - 1)
end

-- Place un marqueur sur la bande. lane : "TOP", "BOTTOM" ou "CENTER".
local function Place(m, bearing, ref, half, span, lane)
	local d = Delta(bearing, ref)
	local out = abs(d) > half
	if out then
		if not db.showEdges then
			m:Hide()
			return
		end
		d = (d > 0) and half or -half
	end
	m:SetPoint("CENTER", band, lane, floor(d / half * span + 0.5), 0)
	m:SetAlpha(out and 0.45 or 1)
	m:Show()
end

-- Aperçu en mode Édition quand on n'est pas groupé
local demoInfo = {
	{ r = 0.67, g = 0.83, b = 0.45, healer = false, ver = -1, b0 = 35 },
	{ r = 0.96, g = 0.55, b = 0.73, healer = true, ver = -2, b0 = -50 },
	{ r = 0.25, g = 0.78, b = 0.92, healer = false, ver = -3, b0 = 120 },
}

local targetDist, wpDist, qDist, homeDist
local wpSmooth, qSmooth, hSmooth

local function UpdateMarkers(now, dt, ref, half, span, heading)
	local haveDir = heading ~= nil
	local haveWorld = haveDir and M.pN ~= nil
	local pInst = M.pInst
	local used = 0

	-- Membres du groupe
	if haveWorld and db.showParty then
		local range = db.range
		for i = 1, #units do
			local u = units[i]
			local n, w, _, inst = UnitPosition(u)
			if not IsSecret(n) and n and inst == pInst then
				local b, dist = BearingTo(n, w)
				local info = unitInfo[u]
				if info and (range == 0 or dist <= range) then
					used = used + 1
					local m = GetMember(used)
					StyleMember(m, info, SafeBool(UnitIsDeadOrGhost(u)))
					b = Smooth(memberSmooth[u], b, dt, dist)
					memberSmooth[u] = b
					Place(m, b, ref, half, span, "BOTTOM")
					-- ping récent de ce membre : anneau pulsant qui s'estompe
					local t = pingAt[u] and now - pingAt[u]
					if t and t < PING_DURATION and db.showPings then
						m.ping:SetAlpha((0.55 + 0.45 * sin(t * 9)) * min(1, (PING_DURATION - t) / 1.5))
						m.ping:Show()
					elseif m.ping:IsShown() then
						m.ping:Hide()
					end
				end
			end
		end
	end
	if M.editMode and used == 0 and haveDir then
		for i = 1, #demoInfo do
			used = used + 1
			local m = GetMember(used)
			StyleMember(m, demoInfo[i], false)
			Place(m, (ref + demoInfo[i].b0) % 360, ref, half, span, "BOTTOM")
			m.ping:SetShown(i == 2) -- aperçu de l'anneau de ping
		end
	end
	for i = used + 1, #memberMarkers do
		if memberMarkers[i]:IsShown() then
			memberMarkers[i]:Hide()
		end
	end

	-- Cible (membre du groupe)
	targetDist = nil
	if haveWorld and db.showTarget and targetUnit then
		local n, w, _, inst = UnitPosition(targetUnit)
		if not IsSecret(n) and n and inst == pInst then
			local b
			b, targetDist = BearingTo(n, w)
			tSmooth = Smooth(tSmooth, b, dt, targetDist)
			SizeDiamond(targetMark)
			Place(targetMark, tSmooth, ref, half, span, "TOP")
		else
			tSmooth = nil
			targetMark:Hide()
		end
	elseif M.editMode and haveDir and db.showTarget then
		SizeDiamond(targetMark)
		Place(targetMark, (ref - 20) % 360, ref, half, span, "TOP")
	else
		targetMark:Hide()
	end

	-- Repère de carte
	wpDist = nil
	if haveWorld and wpN then
		local b
		b, wpDist = BearingTo(wpN, wpW)
		wpSmooth = Smooth(wpSmooth, b, dt, wpDist)
		SizeDiamond(wpMark)
		Place(wpMark, wpSmooth, ref, half, span, "TOP")
	else
		wpSmooth = nil
		wpMark:Hide()
	end

	-- Quête suivie
	qDist = nil
	if haveWorld and qN then
		local b
		b, qDist = BearingTo(qN, qW)
		qSmooth = Smooth(qSmooth, b, dt, qDist)
		SizeDiamond(questMark)
		Place(questMark, qSmooth, ref, half, span, "TOP")
	else
		qSmooth = nil
		questMark:Hide()
	end

	-- Gnomeregan
	homeDist = nil
	local hb
	if haveWorld and db.showHome then
		if M.homeMode == "near" then
			hb, homeDist = BearingTo(M.homeN, M.homeW)
			hSmooth = Smooth(hSmooth, hb, dt, homeDist)
			hb = hSmooth
		elseif M.homeMode == "far" then
			hb = M.homeBearing
		end
	end
	if not hb and M.editMode and haveDir and db.showHome then
		hb = (ref + 70) % 360
	end
	if hb then
		SizeHome()
		Place(homeMark, hb, ref, half, span, "TOP")
	else
		hSmooth = nil
		homeMark:Hide()
	end
end

---------------------------------------------------------------------------
-- Soleil / lune (heure du serveur)
---------------------------------------------------------------------------
local cel = CreateFrame("Frame", nil, border)
cel:SetSize(18, 18)
cel:SetPoint("RIGHT", band, "LEFT", -6, 0)
cel:EnableMouse(true)
local sunGlow = Circle(cel, 20, 1, 0.65, 0.15, 0.35, "BACKGROUND", 0)
local sun = Circle(cel, 13, 1, 0.85, 0.3, 1, "ARTWORK", 0)
local moon = Circle(cel, 12, 0.8, 0.85, 0.95, 1, "ARTWORK", 0)
local moonCut = Circle(cel, 10, 0.1, 0.12, 0.22, 0.95, "ARTWORK", 1)
sunGlow:SetPoint("CENTER")
sun:SetPoint("CENTER")
moon:SetPoint("CENTER")
moonCut:SetPoint("CENTER", 3, 2)

local isDay
local function UpdateCelestial()
	local h, m = GetGameTime()
	local t = (h or 12) + (m or 0) / 60
	local day = (t >= 6 and t < 18)
	if day == isDay then
		return
	end
	isDay = day
	sun:SetShown(day)
	sunGlow:SetShown(day)
	moon:SetShown(not day)
	moonCut:SetShown(not day)
end

cel:SetScript("OnEnter", function(self)
	local h, m = GetGameTime()
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:AddLine(isDay and "Jour" or "Nuit")
	GameTooltip:AddDoubleLine("Heure du serveur", format("%02d:%02d", h or 0, m or 0), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine("Heure locale", date("%H:%M"), 1, 1, 1, 1, 1, 1)
	GameTooltip:Show()
end)
cel:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

---------------------------------------------------------------------------
-- Textes sous la bande (10 fois par seconde, seulement si la valeur change)
---------------------------------------------------------------------------
local headingText = border:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local coordText = border:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
local infoText = border:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
local zoneText = border:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
local TEXTS = { headingText, coordText, infoText, zoneText }

-- Empile seulement les lignes affichées
local function RestackTexts()
	local prev
	for _, fs in ipairs(TEXTS) do
		if fs:IsShown() then
			fs:ClearAllPoints()
			if prev then
				fs:SetPoint("TOP", prev, "BOTTOM", 0, -2)
			else
				fs:SetPoint("TOP", band, "BOTTOM", 0, -9)
			end
			prev = fs
		end
	end
end

local lastHd, lastCx, lastCy, lastTd, lastWd, lastQd, lastGd

local function ResetTexts()
	lastHd, lastCx, lastCy, lastTd, lastWd, lastQd, lastGd = -1, -1, -1, -2, -2, -2, -2
	zoneText.cur = nil
end
ResetTexts()

local function UpdateTexts(heading)
	if db.showHeading then
		local hd = heading and (floor(heading + 0.5) % 360) or -1
		if hd ~= lastHd then
			lastHd = hd
			headingText:SetText(hd >= 0 and format("%s  |cff8c8c8c%d°|r", DirName(heading), hd) or "—")
		end
	end

	if db.showCoords then
		local x, y = M.PlayerMapFrac()
		local cx, cy = x and floor(x * 1000 + 0.5) or -1, y and floor(y * 1000 + 0.5) or -1
		if cx ~= lastCx or cy ~= lastCy then
			lastCx, lastCy = cx, cy
			coordText:SetText(cx >= 0 and format("%.1f, %.1f", cx / 10, cy / 10) or "Position indisponible")
		end
	end

	if db.showDist then
		local td = targetDist and floor(targetDist + 0.5) or -1
		local wd = wpDist and floor(wpDist + 0.5) or -1
		local qd = qDist and floor(qDist + 0.5) or -1
		-- -3 : Gnomeregan sur un autre continent
		local gd = homeDist and floor(homeDist + 0.5) or ((homeMark:IsShown() and M.homeMode == "far") and -3 or -1)
		if td ~= lastTd or wd ~= lastWd or qd ~= lastQd or gd ~= lastGd then
			lastTd, lastWd, lastQd, lastGd = td, wd, qd, gd
			infoText:SetText(
				format(
					"%s%s%s%s",
					td >= 0 and format("|cffff5040Cible %d m|r   ", td) or "",
					wd >= 0 and format("|cff40ff60Repère %d m|r   ", wd) or "",
					qd >= 0 and format("|cffffd820Quête %d m|r   ", qd) or "",
					gd >= 0 and format("|cff3fa0ffGnomeregan %d m|r", gd)
						or (gd == -3 and "|cff3fa0ffGnomeregan : outre-mer|r" or "")
				)
			)
		end
	end
end

local function UpdateZoneText()
	if db and db.showZone then
		local s = (GetMinimapZoneText and GetMinimapZoneText()) or GetZoneText() or ""
		if zoneText.cur ~= s then
			zoneText.cur = s
			zoneText:SetText(s)
		end
	end
end

---------------------------------------------------------------------------
-- Boucle principale (limitée à db.fps, ne tourne que si la bande est visible)
---------------------------------------------------------------------------
local acc, textT, objT, celT = 0, 1, 2, 5
local objErrShown

band:SetScript("OnUpdate", function(_, elapsed)
	acc = acc + elapsed
	if acc < 1 / db.fps then
		return
	end
	local dt = acc
	acc = 0

	local now = GetTime()
	local heading = M.GetHeading()
	M.UpdatePlayerWorld()

	local W, H = band:GetWidth(), band:GetHeight()
	local half = db.fov / 2
	local span = W / 2 - 6
	local ref = 0
	if heading then
		-- arrondi au pixel : évite de tout replacer pour un écart invisible
		local step = half / max(span, 1)
		ref = (floor(heading / step + 0.5) * step) % 360
	end

	LayoutScale(ref, W, H, half, span, heading and 1 or 0.25)
	unknownText:SetShown(heading == nil)
	centerMark:SetShown(heading ~= nil)

	objT = objT + dt
	if objT >= 2 then
		objT = 0
		-- API de Forever mal connue : une erreur ici ne doit pas se répéter toutes les 2 s
		local ok, err = pcall(RefreshObjectives)
		if not ok and not objErrShown then
			objErrShown = true
			GI:Print("boussole : erreur des objectifs, signalée une seule fois (" .. tostring(err) .. ")")
		end
	end

	UpdateMarkers(now, min(dt, 0.1), ref, half, span, heading)

	textT = textT + dt
	if textT >= 0.1 then
		textT = 0
		UpdateTexts(heading)
	end

	celT = celT + dt
	if celT >= 5 then
		celT = 0
		UpdateCelestial()
	end
end)

-- Demande un rafraîchissement rapide des objectifs (regroupe les rafales d'événements)
local function SoonObjectives()
	objT = max(objT, 1.7)
end

---------------------------------------------------------------------------
-- Réglages appliqués
---------------------------------------------------------------------------
function M.ApplySettings()
	band:SetScale(db.scale)
	border:SetScale(db.scale)
	band:SetAlpha(db.alpha)
	border:SetAlpha(db.alpha)
	band:SetSize(db.width, db.height)

	bg:SetAlpha(db.bgAlpha)
	headingText:SetShown(db.showHeading)
	coordText:SetShown(db.showCoords)
	infoText:SetShown(db.showDist)
	zoneText:SetShown(db.showZone)
	RestackTexts()
	cel:SetShown(db.celest)
	ApplyFonts()
	ResetTexts()
	UpdateZoneText()

	if M.overlay then
		M.overlay:SetShown(M.editMode or not db.locked)
	end

	local visible = db.shown or M.editMode
	band:SetShown(visible)
	border:SetShown(visible)

	styleVersion = styleVersion + 1
	lastRef = nil
	isDay = nil
	celT, textT, objT = 5, 1, 2
	UpdateCelestial()
end

function M.OnSettingChanged(key)
	if key == "showRaid" or key == "showParty" or key == "raidIcons" or key == "healers" then
		RebuildRoster()
	end
	M.ApplySettings()
end

-- Change l'échelle sans déplacer la bande à l'écran
function M.SetScale(new)
	local old = db.scale
	db.scale = new
	if db.point and old ~= new then
		db.point[3], db.point[4] = db.point[3] * old / new, db.point[4] * old / new
		band:ClearAllPoints()
		band:SetPoint(db.point[1], UIParent, db.point[2], db.point[3], db.point[4])
	end
	M.ApplySettings()
end

function M.Toggle()
	if not db then
		return
	end
	db.shown = not db.shown
	M.ApplySettings()
end

function M.ResetLayout()
	db.point = nil
	db.width, db.height, db.fov, db.scale = 300, 26, 180, 1
	band:ClearAllPoints()
	band:SetPoint("TOP", UIParent, "TOP", 0, -120)
	M.ApplySettings()
end

---------------------------------------------------------------------------
-- Événements (distribués par le cœur : M[événement])
---------------------------------------------------------------------------
function M:PLAYER_ENTERING_WORLD()
	M.ClearMapCache()
	M.UpdateCurrentMap()
	UpdateZoneText()
	RebuildRoster()
	SoonObjectives()
end

function M:GROUP_ROSTER_UPDATE()
	RebuildRoster()
end

function M:PLAYER_ROLES_ASSIGNED()
	RefreshInfo()
end
M.RAID_TARGET_UPDATE = M.PLAYER_ROLES_ASSIGNED

function M:PLAYER_TARGET_CHANGED()
	FindTargetUnit()
end

function M:ZONE_CHANGED()
	M.UpdateCurrentMap()
	UpdateZoneText()
	SoonObjectives()
end
M.ZONE_CHANGED_INDOORS = M.ZONE_CHANGED
M.ZONE_CHANGED_NEW_AREA = M.ZONE_CHANGED

function M:USER_WAYPOINT_UPDATED()
	SoonObjectives()
end
M.SUPER_TRACKING_CHANGED = M.USER_WAYPOINT_UPDATED
M.QUEST_LOG_UPDATE = M.USER_WAYPOINT_UPDATED

-- Qui a pingé ? Par GUID, sinon par nom (sans le royaume). Données masquées en combat : ignorées.
local function FindPinger(name, guid)
	if IsSecret(guid) then
		guid = nil
	end
	if IsSecret(name) then
		name = nil
	end
	name = name and name:match("^[^-]+")
	for i = 1, #units do
		local u = units[i]
		if guid and unitGUID[u] == guid then
			return u
		end
		if not guid and name then
			local n = UnitName(u)
			if not IsSecret(n) and n == name then
				return u
			end
		end
	end
end

function M:CHAT_MSG_PING(_, playerName, _, _, _, _, _, _, _, _, _, guid)
	local u = FindPinger(playerName, guid)
	if u then
		pingAt[u] = GetTime()
	end
	if M.debug then
		GI:Print(
			format(
				"[diag] ping de %s : %s%s",
				IsSecret(playerName) and "(secret)" or tostring(playerName),
				u and ("membre affiché (" .. u .. ")") or "pas un membre affiché",
				db.showPings and "" or " — option « Pings » décochée"
			)
		)
	end
end

local EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"GROUP_ROSTER_UPDATE",
	"PLAYER_ROLES_ASSIGNED",
	"RAID_TARGET_UPDATE",
	"PLAYER_TARGET_CHANGED",
	"ZONE_CHANGED",
	"ZONE_CHANGED_INDOORS",
	"ZONE_CHANGED_NEW_AREA",
	"USER_WAYPOINT_UPDATED",
	"SUPER_TRACKING_CHANGED",
	"QUEST_LOG_UPDATE",
	"CHAT_MSG_PING",
}

-- Appelé au démarrage du module (Options.lua), une fois les réglages chargés
function M.InitBande()
	db = M.db
	if db.point then
		band:ClearAllPoints()
		band:SetPoint(db.point[1], UIParent, db.point[2], db.point[3], db.point[4])
	end
	for _, ev in ipairs(EVENTS) do
		M:RegisterEvent(ev)
	end
	M.UpdateCurrentMap()
	RebuildRoster()
end
