--[[----------------------------------------------------------------------------
	FightRecorder

	2014-2020
	Sanex @ EU-Arathor / ahak @ Curseforge

	This should show graphs about your progress when killing bosses HP- and
	timewise and also keep track and show your progress towards the first kill.

	no public source yet
	crappy code, hacky features added on top of already hackier features and
	probably breaking something in the process...
	...or at least everything will fall apart when I remove some old "unused"
	code or features.

	FEATURE CREEP LIST AKA TODO:
	- Compression of dataDB for encounters?
		This would only reduce the size of 'SavedVariables' and nothing else
		would be really gained from this.
	- Something mind to the endless local-scoping
		No need to local-scope every function we call, start with the functions
		used by the snapshotting and extend to the most used ones after that.
	- Remove all old unused and commented out code
		You are not going to use it anymore, why save it and make this file
		longer than is needs to be?
		Some of it has been already removed, but there is still ton of stuff.
----------------------------------------------------------------------------]]--
local ADDON_NAME, ns = ... -- Addon name and private namespace


--------------------------------------------------------------------------------
-- Local upvalues
--------------------------------------------------------------------------------
local _G = _G
-- Try to limit local scoping, these are used in the snapshotting and are bombarded more often than other functions
local GetTime = _G.GetTime
local IsInRaid = _G.IsInRaid
local math_ceil = _G.math.ceil
local math_floor = _G.math.floor
local strsplit = _G.strsplit
local tonumber = _G.tonumber
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitBuff = _G.UnitBuff
local UnitExists = _G.UnitExists
local UnitGUID = _G.UnitGUID
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitName = _G.UnitName
--[[
local abs = _G.abs
--local AuraUtil = _G.AuraUtil -- Replaces _G.UnitBuff... Replaced by _G.UnitAura
local C_Map = _G.C_Map
local C_Timer = _G.C_Timer
local ChatFrame3 = _G.ChatFrame3
local date = _G.date
local DEBUG_CHAT_FRAME = _G.DEBUG_CHAT_FRAME
local DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME
--local EJ_GetCurrentInstance = _G.EJ_GetCurrentInstance -- Replaced by _G.EJ_GetInstanceForMap + _G.C_Map.GetBestMapForUnit
local EJ_GetEncounterInfoByIndex = _G.EJ_GetEncounterInfoByIndex -- Populate RaidData.lua
local EJ_GetInstanceByIndex = _G.EJ_GetInstanceByIndex -- Populate RaidData.lua
local EJ_GetInstanceForMap = _G.EJ_GetInstanceForMap
local EJ_GetInstanceInfo = _G.EJ_GetInstanceInfo
local EJ_GetNumTiers = _G.EJ_GetNumTiers -- Populate RaidData.lua
local EJ_SelectInstance = _G.EJ_SelectInstance -- Populate RaidData.lua
local EJ_SelectTier = _G.EJ_SelectTier -- Populate RaidData.lua
local format = _G.format -- Print & Debug
local GetDifficultyInfo = _G.GetDifficultyInfo
local GetGuildInfo = _G.GetGuildInfo
local GetNumGroupMembers = _G.GetNumGroupMembers -- _G.GROUP_ROSTER_UPDATE
local GetRaidRosterInfo = _G.GetRaidRosterInfo -- Replaced by _G.InGuildParty, still used for names in guild check
local GetServerTime = _G.GetServerTime
local GetTime = _G.GetTime
local GetUnitName = _G.GetUnitName
local InCombatLockdown = _G.InCombatLockdown
local InGuildParty = _G.InGuildParty -- Replaces _G.GetRaidRosterInfo
local IsControlKeyDown = _G.IsControlKeyDown
local IsEncounterInProgress = _G.IsEncounterInProgress
local IsInRaid = _G.IsInRaid
local IsLoggedIn = _G.IsLoggedIn
local IsShiftKeyDown = _G.IsShiftKeyDown
local math = _G.math
--local MAX_RAID_MEMBERS = _G.MAX_RAID_MEMBERS -- Replaced by _G.InGuildParty
local next = _G.next
local pairs = _G.pairs
local print = _G.print -- print_r
local setmetatable = _G.setmetatable
local sort = _G.sort
local StaticPopup_Show = _G.StaticPopup_Show
--local StaticPopupDialogs = _G.StaticPopupDialogs
local string = _G.string
local strjoin = _G.strjoin -- Print & Debug
local strsplit = _G.strsplit
local tonumber = _G.tonumber
local tostring = _G.tostring
local tostringall = _G.tostringall
local tremove = _G.tremove
local type = _G.type
local UnitAffectingCombat = _G.UnitAffectingCombat
--local UnitAura = _G.UnitAura -- Replaces _G.AuraUtil... Replaced by _G.UnitBuff
local UnitBuff = _G.UnitBuff -- Replaced by _G.AuraUtil... Replaces _G.UnitAura
local UnitExists = _G.UnitExists -- lastPercent
local UnitFullName = _G.UnitFullName -- _G.UnitName return values will change if the unit in question is under the effects of  [Lifegiving Seed] (see Wowhead comments) or a similar effect, does this do same?
local UnitGUID = _G.UnitGUID
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsVisible = _G.UnitIsVisible
local UnitName = _G.UnitName
local unpack = _G.unpack
local wipe = _G.wipe
]]


--------------------------------------------------------------------------------
-- Libs
--------------------------------------------------------------------------------
local AceGUI = LibStub("AceGUI-3.0")


--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local dataDB, bossDB, progressDB, phaser, councilEncounter, ignorePhasesEncounter, isThisCouncilEncounter
local timeLimit = 10 -- Lower limit for fight lenght to be processed
local jammer, jammerThreshold = 0, 5 -- Don't record if multiple encounters start within the threshold
local startTime, timer = 0, 0
local lastPercent, previousPercent = {}, {} -- lastPercent
local phase, lastPhase = 1, 1
local phaseOrder = {}
local minSize = 2 -- Minimum width of the graph-lines
local numGroupMembers = 0 -- Size of the group, update on GROUP_ROSTER_UPDATE event
local graphData = {}
local graphDataMetaTable = {__index = function(self, index)
	local new = {
		health = {}
	}
	self[index] = new
	return new
end}
local dataDefaults = {
	data = {},
	info = {},
	name = {}
}
local recUnits = {
	--"player", -- Debug
	--"target", -- Debug
	"boss1",
	"boss2",
	"boss3",
	"boss4",
	"boss5"
}
local buffsTable = {
	--"Guard", -- Debug
	"Heroism", -- 32182
	"Bloodlust", -- 2825
	"Time Warp", -- 80353
	"Ancient Hysteria", -- 90355
	"Netherwinds", -- 160452
	"Drums of Rage", -- 146555 (http://www.wowhead.com/item=102351/drums-of-rage#comments:id=1912641)
	"Drums of Fury", -- 178207 (http://www.wowhead.com/guide=1100#primary-burst-haste)
	"Drums of the Mountain", -- 230935 (https://www.wowhead.com/item=142406/drums-of-the-mountain#comments)
	"Drums of the Maelstrom" -- 256740 (https://www.wowhead.com/item=154167/drums-of-the-maelstrom#comments)
}

local colorTable = {
	{ 0, 1, 0, 1 }, -- Green
	{ 1, 0, 0, 1 }, -- Red
	{ 1, 1, 0, 1 }, -- Yellow
	{ 1, 0, 1, 1 }, -- Purple
	{ 0, 1, 1, 1 }, -- Cyan
	{ 0, 0, 1, 1 }, -- Blue
	{ 1, 1, 1, 1 } -- White
}
--[[
local colorTable = { -- "Borrowed" from LibGraph
	{0.9, 0.1, 0.1},
	{0.1, 0.9, 0.1},
	{0.1, 0.1, 0.9},
	{0.9, 0.9, 0.1},
	{0.9, 0.1, 0.9},
	{0.1, 0.9, 0.9},
	{0.9, 0.9, 0.9},
	{0.5, 0.1, 0.1},
	{0.1, 0.5, 0.1},
	{0.1, 0.1, 0.5},
	{0.5, 0.5, 0.1},
	{0.5, 0.1, 0.5},
	{0.1, 0.5, 0.5},
	{0.5, 0.5, 0.5},
	{0.75, 0.15, 0.15},
	{0.15, 0.75, 0.15},
	{0.15, 0.15, 0.75},
	{0.75, 0.75, 0.15},
	{0.75, 0.15, 0.75},
	{0.15, 0.75, 0.75},
	{0.9, 0.5, 0.1},
	{0.1, 0.5, 0.9},
	{0.9, 0.1, 0.5},
	{0.5, 0.9, 0.1},
	{0.5, 0.1, 0.9},
	{0.1, 0.9, 0.5}
}
]]--
local difficultyTable = {
	[14] = PLAYER_DIFFICULTY1,
	[15] = PLAYER_DIFFICULTY2,
	[16] = PLAYER_DIFFICULTY6,
	[33] = PLAYER_DIFFICULTY_TIMEWALKER
}
-- "Import" stuff from RaidData.lua so I don't have to keep typing 'ns' all the time
local recordThis = ns.recordThis
local instanceIDFixes = ns.instanceIDFixes
local councilStyleEncounters = ns.councilStyleEncounters
local ignorePhasesEncounters = ns.ignorePhasesEncounters
local ignoredNames = ns.ignoredNames
local RaidEncounterIDs = ns.RaidEncounterIDs
local BossAdds = ns.BossAdds
local RaidBosses = ns.RaidBosses
local orderTable = ns.orderTable


--------------------------------------------------------------------------------
-- Debuging & Output
--------------------------------------------------------------------------------
local DEBUGMODE = true
local DEBUG_CHAT_FRAME = ChatFrame4
local function Debug(text, ...)
	if not DEBUGMODE then return end

	if text then
		if text:match("%%[dfqsx%d%.]") then
			(DEBUG_CHAT_FRAME or ChatFrame3):AddMessage("|cffff9999"..ADDON_NAME..":|r " .. format(text, ...))
		else
			(DEBUG_CHAT_FRAME or ChatFrame3):AddMessage("|cffff9999"..ADDON_NAME..":|r " .. strjoin(" ", text, tostringall(...)))
		end
	end
end

local function Print(text, ...)
	if text then
		if text:match("%%[dfqs%d%.]") then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00".. ADDON_NAME ..":|r " .. format(text, ...))
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00".. ADDON_NAME ..":|r " .. strjoin(" ", text, tostringall(...)))
		end
	end
end

-- print_r
local function print_r ( t )
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
						print(indent..string.rep(" ",string.len(pos)+6).."}")
					else
						print(indent.."["..pos.."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end
	sub_print_r(t," ")
end


--------------------------------------------------------------------------------
-- Table functions
--------------------------------------------------------------------------------
local function _initDB(db, defaults)
	if type(db) ~= "table" then db = {} end
	if type(defaults) ~= "table" then return db end
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			db[k] = _initDB(db[k], v)
		elseif type(v) ~= type(db[k]) then
			db[k] = v
		end
	end
	return db
end

local function _cleanDB(db) -- Remove empty subtables
	if type(db) ~= "table" then return {} end
	for k, v in pairs(db) do
		if type(v) == "table" then
			if not next(_cleanDB(v)) then
				db[k] = nil
			end
		end
	end
	return db
end


--------------------------------------------------------------------------------
-- Round function, copied from http://lua-users.org/wiki/SimpleRound
--------------------------------------------------------------------------------
local function _round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end


--------------------------------------------------------------------------------
-- Slice function, copied from https://stackoverflow.com/a/24823383
--------------------------------------------------------------------------------
local function _slice(tbl, first, last, step)
	local sliced = {}

	for i = first or 1, last or #tbl, step or 1 do
		sliced[#sliced+1] = tbl[i]
	end

	return sliced
end


--------------------------------------------------------------------------------
-- Check if raid is Guild-raid
--------------------------------------------------------------------------------
--[[
-- Replaced with _G.InGuildParty()
local function _checkForGuildRaid()
	local playerGuild = GetGuildInfo("player")
	local totalCount, guildCount = 0, 0

	--for i = 1, GetNumGroupMembers() do
	for i = 1, MAX_RAID_MEMBERS do
		local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
		if name and online then -- Exists and is online
			totalCount = totalCount + 1
			local guildName = GetGuildInfo("raid"..i)

			--Debug("> Online", name, guildName)
			if guildName == playerGuild then
				guildCount = guildCount + 1
			else
				--Debug("> !Guild", name, guildName)
			end
		end
	end

	if totalCount == 0 then return end -- Something went wrong

	local percentage = guildCount / totalCount

	-- Check if we meet the metrics to count as guild group
	if percentage >= guildTresholdPercentage and totalCount >= guildTresholdCount then
		guildRaid = true
	else
		guildRaid = false
	end

	--Debug("GuildCheck: %s (%d%% %d/%d - Check: %d)", tostring(guildRaid), _round(percentage * 100), guildCount, totalCount, GetNumGroupMembers())
	return _round(percentage * 100), guildCount, totalCount
end
]]


--------------------------------------------------------------------------------
-- Event Frame
--------------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)


--------------------------------------------------------------------------------
-- Minimap texts
--------------------------------------------------------------------------------
do
	f.TimerTextLeft = _G.Minimap:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.TimerTextLeft:SetJustifyH("RIGHT")
	f.TimerTextLeft:SetText("Combat:")
	f.TimerTextLeft:SetPoint("BOTTOMRIGHT", _G.Minimap, "BOTTOM", -1, 0)

	f.TimerTextRight = _G.Minimap:CreateFontString(nil, "OVERLAY", "GameFontHighLight")
	f.TimerTextRight:SetJustifyH("LEFT")
	f.TimerTextRight:SetFormattedText("%02d:%02d.%02d", 0, 0, 0)
	f.TimerTextRight:SetPoint("BOTTOMLEFT", _G.Minimap, "BOTTOM", 1, 0)
end


--------------------------------------------------------------------------------
-- View Frame
--------------------------------------------------------------------------------
local function _TrimTree(inputData) -- Remove empty tables
	for instanceID, instanceData in pairs(inputData) do
		for encounterID, encounterData in pairs(instanceData) do
			for difficultyID, difficultyData in pairs(encounterData) do
				if not difficultyData and not next(difficultyData.data) then
					dataDB[instanceID][encounterID][difficultyID] = nil
					if bossDB[instanceID] and bossDB[instanceID][encounterID] and bossDB[instanceID][encounterID][difficultyID] then
						bossDB[instanceID][encounterID][difficultyID] = nil
					end
					progressDB[instanceID][encounterID][difficultyID] = nil
				end
			end

			if not next(encounterData) then
				dataDB[instanceID][encounterID] = nil
				if bossDB[instanceID] and bossDB[instanceID][encounterID] then
					bossDB[instanceID][encounterID] = nil
				end
				progressDB[instanceID][encounterID] = nil
			end
		end

		if not next(instanceData) then
			dataDB[instanceID] = nil
			if bossDB[instanceID] then
				bossDB[instanceID] = nil
			end
			progressDB[instanceID] = nil
		end
	end
end

local function _UpdateTree(inputData)
	_TrimTree(inputData)
	local expansions, tree = {}, {}
	local i, e, d = 1, 1, 1
	for instanceID, instanceData in pairs(inputData) do
		if orderTable.r[instanceID] then -- Save data for separator showing/hiding
			expansions[string.len(orderTable.r[instanceID])] = true
		end

		tree[i] = {}
		if not tree[i].value then tree[i].value = instanceID end
		if not tree[i].text then
			tree[i].text = (EJ_GetInstanceInfo(instanceID))
				or bossDB[instanceID] and bossDB[instanceID]["name"]
				or "Unknown Instance"
		end
		tree[i].children = tree[i].children or {}

		for encounterID, encounterData in pairs(instanceData) do
			tree[i].children[e] = {}
			if not tree[i].children[e].value then tree[i].children[e].value = encounterID end
			if not tree[i].children[e].text then
				tree[i].children[e].text = (RaidEncounterIDs[instanceID] and RaidEncounterIDs[instanceID][encounterID]) and RaidEncounterIDs[instanceID][encounterID]
					or (bossDB[instanceID] and bossDB[instanceID][encounterID]) and bossDB[instanceID][encounterID]["name"]
					or "Unknown Boss"
			end
			tree[i].children[e].children = tree[i].children[e].children or {}

			for difficultyID in pairs(encounterData) do
				local data = inputData[instanceID][encounterID][difficultyID].info
				if not tree[i].children[e].text or tree[i].children[e].text == "Unknown Boss" then
					tree[i].children[e].text = data and data.encounterName
						or "Unknown Boss"
				end

				tree[i].children[e].children[d] = {}
				if not tree[i].children[e].children[d].value then tree[i].children[e].children[d].value = difficultyID end
				if not tree[i].children[e].children[d].text then
					tree[i].children[e].children[d].text = (GetDifficultyInfo(difficultyID))
						or difficultyTable[difficultyID]
						or "Unknown Difficulty"
				end

				d = d + 1
			end

			sort(tree[i].children[e].children, function(a, b)
				if (a and b) then
					return a.value < b.value
				else
					return a < b
				end
			end)

			d = 1
			e = e + 1
		end

		sort(tree[i].children, function(a, b)
			if (a and b) then
				if (orderTable.e[a.value] and orderTable.e[b.value]) then
					return orderTable.e[a.value] < orderTable.e[b.value]
				else
					return a.value < b.value
				end
			else
				return a < b
			end
		end)

		e = 1
		i = i + 1
	end

	-- Add separators for xpacks to split raids from different eras
	local function _padTitle(title) -- Create xpack-titles padded with '='-characters
		--[[local s = "=== " .. title .. " "
		while s:len() < 25 do
			s = s .. "="
		end]]
		--[[local s = "=== " .. title
		local l = 24 - string.len(s) -- Used to be 25, too long for some titles
		if l > 0 then -- Check if we need to pad at the end
			s = s .. " " .. string.rep("=", l - 1) -- -1 for the added space added after the 'title'
		end

		return s]]

		-- Even 24 will be too long when expanding enough menus to make the scrollbar to appear.
		-- You want to use value 20 if you don't want to see the three dots (...) when scrollbar appears.
		-- This value is scientifically proven to be exactly right value for my personal use with my default UI Font.
		-- The '-5' comes from two spaces around the 'title' and three leading equal signs (===).
		local properWidth = (20 - 5) -- This is right for 'PT Sans Narrow' size 12 with OUTLINE!
		return strtrim(string.format("=== %s %s", title, string.rep("=", properWidth - string.len(title)))) or string.format("=== %s", title)
	end

	local function _addSeparator(value, text)
		if orderTable.r[value] then
			tree[#tree + 1] = { value = value, text = _padTitle(text), disabled = true }
		end
	end

	--local gameVersion = 8
	local gameVersion = EJ_GetNumTiers() or math.floor(select(4,GetBuildInfo()) / 10000) -- Remember to update the orderTable in RaidData.lua on new expansion
	-- We have that -1/+1 here just to not have it later down in the if/elseif/else-comparison and keep the gameVersion and comparisons in line with actual game versions
	for x = 0, (gameVersion - 1) do
		--Debug(">", x, tostring(expansions[x]))
		if expansions[x + 1] then
			-- Only add separator if there are saved encounters for that expansion
			if (gameVersion - x) == 1 then
				_addSeparator(100000, "CLASSIC")
			elseif (gameVersion - x) == 2 then
				_addSeparator(100001, "TBC")
			elseif (gameVersion - x) == 3 then
				_addSeparator(100002, "WRATH")
			elseif (gameVersion - x) == 4 then
				_addSeparator(100003, "CATA")
			elseif (gameVersion - x) == 5 then
				_addSeparator(100004, "MOP")
			elseif (gameVersion - x) == 6 then
				_addSeparator(100005, "WOD")
			elseif (gameVersion - x) == 7 then
				_addSeparator(100006, "LEGION")
			elseif (gameVersion - x) == 8 then
				_addSeparator(100007, "BFA")
			elseif (gameVersion - x) == 9 then
				_addSeparator(100008, "SL")
			else
				Debug(">>> Separators, eh??? Check orderTable in RaidData.lua", x, gameVersion)
			end
		end
	end
	-- End separators, back to normal business

	sort(tree, function(a, b)
		if (a and b) then
			if (orderTable.r[a.value] and orderTable.r[b.value]) then
				return orderTable.r[a.value] < orderTable.r[b.value]
			else
				return a.value < b.value
			end
		else
			return a < b
		end
	end)

	return tree
end

local Graph, ProgressGraph, g, p
local Frame, list, iconButton
do
	-- Callback function for OnGroupSelected
	local function _SelectGroup(container, event, group)
		local instanceID, encounterID, difficultyID = strsplit("\001", group)
		instanceID, encounterID, difficultyID = tonumber(instanceID), tonumber(encounterID), tonumber(difficultyID)
		--Debug("SelectGroup:", group, "-", instanceID, encounterID, difficultyID)

		if IsShiftKeyDown() and IsControlKeyDown() then
			if instanceID and encounterID and difficultyID then
				local dialogFrame = StaticPopup_Show("FIGHTRECORDER_REMOVE_CONFIRM", "DIFFICULTY")
				if dialogFrame then
					dialogFrame.data = { instanceID, encounterID, difficultyID }
				end
			elseif instanceID and encounterID then
				local dialogFrame = StaticPopup_Show("FIGHTRECORDER_REMOVE_CONFIRM", "ENCOUNTER")
				if dialogFrame then
					dialogFrame.data = { instanceID, encounterID, difficultyID }
				end
			elseif instanceID then
				local dialogFrame = StaticPopup_Show("FIGHTRECORDER_REMOVE_CONFIRM", "INSTANCE")
				if dialogFrame then
					dialogFrame.data = { instanceID, encounterID, difficultyID }
				end
			end

			list:SetTree(_UpdateTree(dataDB))
		else
			if instanceID and encounterID and difficultyID then
				if dataDB[instanceID] then
					if dataDB[instanceID][encounterID] then
						if dataDB[instanceID][encounterID][difficultyID] then
							local info = dataDB[instanceID][encounterID][difficultyID].info
							if info.endStatus == 1 then
								Frame:SetStatusText(string.format("Record kill on %s %s (%d player) (%02d:%02d.%02d) on %s as %s", (GetDifficultyInfo(info.difficultyID) or "unknown difficulty"), info.encounterName, info.raidSize, math.floor(info.timer/60), info.timer % 60, ((info.timer - math.floor(info.timer)) * 100), (info.timestamp or "n/a"), (info.playerName or "n/a")))
							elseif info.bestTry then
								Frame:SetStatusText(string.format("Best try on %s %s (%d player) was %.2f%% (%02d:%02d.%02d) on %s as %s", GetDifficultyInfo(info.difficultyID) or "unknown difficulty", info.encounterName, info.raidSize, info.bestTry, math.floor(info.timer/60), info.timer % 60, (info.timer - math.floor(info.timer)) * 100, (info.timestamp or "n/a"), (info.playerName or "n/a")))
							end

							f:selectDrawing(1, dataDB[instanceID][encounterID][difficultyID])
							if progressDB[instanceID] and progressDB[instanceID][encounterID] and progressDB[instanceID][encounterID][difficultyID] then
								--f:selectDrawing(2, progressDB[instanceID][encounterID][difficultyID])
								f:selectDrawing(2, progressDB[instanceID][encounterID][difficultyID], info.councilEncounter)
							else
								f:selectDrawing(2)
							end
							Graph:Show()
							ProgressGraph:Hide()
							Frame:Show()
						else
							Debug("No difficultyID", instanceID, encounterID, difficultyID)
						end
					else
						Debug("No encounterID", instanceID, encounterID, difficultyID)
					end
				else
					Debug("No instanceID", instanceID, encounterID, difficultyID)
				end
			end
		end
	end

	-- Callback function for OnClick
	local function _ClickIcon(button)
		if not Graph and ProgressGraph then
			Print("Nouh!")
		else
			if Graph:IsShown() then
				--Print("-> ProgressGraph")
				Graph:Hide()
				ProgressGraph:Show()
			else
				--Print("-> Graph")
				Graph:Show()
				ProgressGraph:Hide()
			end
			--Print("Clickety Click")
		end
	end

	Frame = AceGUI:Create("Frame")
	Frame:SetTitle(ADDON_NAME)
	Frame:SetStatusText(ADDON_NAME.." Frame created...")
	Frame:SetWidth(985)
	Frame:SetHeight(530)
	Frame:EnableResize(false)
	Frame:SetLayout("Flow")

	list = AceGUI:Create("TreeGroup")
	list:SetFullWidth(true)
	list:SetFullHeight(true)
	list:SetTreeWidth(false)
	list:SetLayout("Fill")
	--list:SetTree(tree)
	list:SetCallback("OnGroupSelected", _SelectGroup)

	Frame:AddChild(list)

	iconButton = AceGUI:Create("Icon")
	--iconButton:SetImage("Interface\\Icons\\Spell_Nature_GroundingTotem")
	--iconButton:SetImageSize(32, 32)
	iconButton:SetImageSize(list.content:GetWidth(), list.content:GetHeight())
	iconButton:SetCallback("OnClick", _ClickIcon)

	list:AddChild(iconButton)

	--Frame:Show()
	Frame:Hide()
end

StaticPopupDialogs["FIGHTRECORDER_REMOVE_CONFIRM"] = {
	text = "Are you sure you want to delete this %s entry?",
	button1 = YES,
	button2 = NO,
	sound = 839, --"igCharacterInfoOpen",
	OnAccept = function(self, data)
		local instanceID, encounterID, difficultyID = unpack(self.data)
		if instanceID and encounterID and difficultyID then
			dataDB[instanceID][encounterID][difficultyID] = nil
			if bossDB[instanceID] and bossDB[instanceID][encounterID] and bossDB[instanceID][encounterID][difficultyID] then
				bossDB[instanceID][encounterID][difficultyID] = nil
			end
			progressDB[instanceID][encounterID][difficultyID] = nil
		elseif instanceID and encounterID then
			dataDB[instanceID][encounterID] = nil
			if bossDB[instanceID] and bossDB[instanceID][encounterID] then
				bossDB[instanceID][encounterID] = nil
			end
			progressDB[instanceID][encounterID] = nil
		elseif instanceID then
			dataDB[instanceID] = nil
			if bossDB[instanceID] then
				bossDB[instanceID] = nil
			end
			progressDB[instanceID] = nil
		end

		list:SetTree(_UpdateTree(dataDB))
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1
}


--------------------------------------------------------------------------------
-- Graph
--------------------------------------------------------------------------------
local maxHeight = 405
local maxWidth = 720
local halfHeight = maxHeight / 2
local halfWidth = maxWidth / 2
Graph = CreateFrame("Frame", ADDON_NAME.."_Graph", list.content)
Graph:SetSize(maxWidth, maxHeight)
Graph:SetPoint("RIGHT", list.content, "RIGHT", -6, 12)


--------------------------------------------------------------------------------
-- ProgressGraph
--------------------------------------------------------------------------------
ProgressGraph = CreateFrame("Frame", ADDON_NAME.."_ProgressGraph", list.content)
ProgressGraph:SetSize(maxWidth, maxHeight)
ProgressGraph:SetPoint("RIGHT", list.content, "RIGHT", -6, 12)
ProgressGraph:Hide()


--------------------------------------------------------------------------------
-- Labels for graphs
--------------------------------------------------------------------------------
local fontStrings, PfontStrings = {}, {}
local function _releaseString(s, tableSelector)
	local tbl = tableSelector == 1 and fontStrings or PfontStrings
	s:ClearAllPoints()
	s:Hide()
	s:SetText("")
	tbl[#tbl + 1] = s
end

local function _getString(tableSelector)
	local tbl = tableSelector == 1 and fontStrings or PfontStrings
	local frame = tableSelector == 1 and Graph or ProgressGraph
	local s

	if #tbl > 0 then
		s = tremove(tbl)
		s:Show()
	else
		s = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	end

	return s
end

local markerTextures, PmarkerTextures = {}, {}
local function _releaseMarker(t, tableSelector)
	local tbl = tableSelector == 1 and markerTextures or PmarkerTextures
	t:ClearAllPoints()
	t:Hide()
	tbl[#tbl + 1] = t
end

local function _getMarker(tableSelector)
	local tbl = tableSelector == 1 and markerTextures or PmarkerTextures
	local frame = tableSelector == 1 and Graph or ProgressGraph
	local t

	if #tbl > 0 then
		t = tremove(tbl)
		t:Show()
	else
		t = frame:CreateTexture(nil, "OVERLAY")
		t:SetColorTexture(1, 1, 1, 1)
		t:SetSize(10, 10)
	end

	return t
end

--------------------------------------------------------------------------------
local xLabels, yLabels , activeMarkers, activeMarkerStrings = {}, {}, {}, {}
local function _labelAxes(maxValue)
	-- X-axis
	local minutes, spacer
	if maxValue then
		minutes = math.floor(maxValue / 60)
		spacer = maxWidth / maxValue * 60
	end

	if minutes and minutes > 0 then
		for i = 1, #Graph.Xlines do
			Graph.Xlines[i]:Hide()
			Graph.Xlines[i]:ClearAllPoints()
		end

		for i = 1, minutes do
			local s = _getString(1)
			s:SetFormattedText("%02d:%02d", i, 0)
			s:SetPoint("TOP", Graph, "BOTTOM", (i * spacer) - halfWidth, -2)

			xLabels[#xLabels + 1] = s

			if Graph.Xlines[i] then
				Graph.Xlines[i]:Show()
				Graph.Xlines[i]:SetPoint("CENTER", Graph, "CENTER", (i * spacer) - halfWidth, 0)
			end
		end
	elseif minutes == 0 and maxValue >= 10 then -- Less than a minute long fight
		local seconds = math.floor(maxValue / 10)
		spacer = maxWidth / maxValue * 10

		for i = 1, #Graph.Xlines do
			Graph.Xlines[i]:Hide()
			Graph.Xlines[i]:ClearAllPoints()
		end

		for i = 1, seconds do
			local s = _getString(1)
			s:SetFormattedText("%02d:%02d", 0, i * 10)
			s:SetPoint("TOP", Graph, "BOTTOM", (i * spacer) - halfWidth, -2)

			xLabels[#xLabels + 1] = s

			if Graph.Xlines[i] then
				Graph.Xlines[i]:Show()
				Graph.Xlines[i]:SetPoint("CENTER", Graph, "CENTER", (i * spacer) - halfWidth, 0)
			end
		end
	else
		for i = 1, 10 do
			local s = _getString(1)
			s:SetFormattedText("%02d:%02d", i, 0)
			s:SetPoint("TOP", Graph, "BOTTOM", (i * maxWidth / 10) - halfWidth, -2)

			xLabels[#xLabels + 1] = s

			if Graph.Xlines[i] then
				Graph.Xlines[i]:Show()
				Graph.Xlines[i]:SetPoint("CENTER", Graph, "CENTER", (i * maxWidth / 10) - halfWidth, 0)
			end
		end
	end

	if maxValue and maxValue > (minutes * 60) then -- Max value isn't full minute
		local s = _getString(1)
		s:SetFormattedText("%02d:%02d", math.floor(maxValue / 60), maxValue % 60)
		s:SetPoint("TOP", Graph, "BOTTOM", halfWidth, -2)

		local _, _, _, xOfs = xLabels[#xLabels]:GetPoint()
		if s:GetStringWidth() > (halfWidth - xOfs) then -- If the space is smaller than string, hide it
			_releaseString(s, 1)
		else -- There is enough space for the string, show the string
			xLabels[#xLabels + 1] = s
		end
	end

	-- Y-axis
	for i = 1, 10 do
		local s = _getString(1)
		s:SetText((i*10).."%")
		s:SetPoint("RIGHT", Graph, "LEFT", -2, (i * maxHeight / 10) - halfHeight)

		yLabels[#yLabels + 1] = s
	end
end

do
	Graph.nodes = {}
	Graph.buffs = {}
	Graph.phases = {}
	Graph.Ylines = {}
	Graph.Xlines = {}

	for i = 1, 10 do -- Percent lines
		local h = Graph:CreateTexture(nil, "BACKGROUND")
		h:SetWidth(maxWidth)
		--h:SetHeight(minSize)
		h:SetHeight(1)
		h:SetPoint("CENTER", Graph, "CENTER", 0, (i * maxHeight / 10) - halfHeight)
		h:SetColorTexture(.5, .5, .5, .5)
		Graph.Ylines[i] = h

		local v = Graph:CreateTexture(nil, "BACKGROUND")
		--v:SetWidth(minSize)
		v:SetWidth(1)
		v:SetHeight(maxHeight)
		v:SetPoint("CENTER", Graph, "CENTER", (i * maxWidth / 10) - halfWidth, 0)
		v:SetColorTexture(.5, .5, .5, .5)
		Graph.Xlines[i] = v
	end

	local yaxis = Graph:CreateTexture(nil, "FULLSCREEN_DIALOG") -- "OVERLAY")
	yaxis:SetWidth(1)
	yaxis:SetHeight(maxHeight + 2)
	yaxis:SetPoint("RIGHT", Graph, "LEFT")
	yaxis:SetColorTexture(1, 1, 1, 1)
	Graph.YAxis = yaxis

	local xaxis = Graph:CreateTexture(nil, "FULLSCREEN_DIALOG") -- "OVERLAY")
	xaxis:SetWidth(maxWidth + 2)
	xaxis:SetHeight(1)
	xaxis:SetPoint("TOP", Graph, "BOTTOM")
	xaxis:SetColorTexture(1, 1, 1, 1)
	Graph.XAxis = xaxis

	_labelAxes()
end

--------------------------------------------------------------------------------
local PxLabels, PyLabels , PactiveMarkers, PactiveMarkerStrings = {}, {}, {}, {}
local function _labelProgressAxes(maxValue)
	-- X-axis
	local divider = 5

	local division, spacer, correction
	if maxValue then
		division = math.floor(maxValue / divider)
		spacer = maxWidth / maxValue * divider
		correction = maxWidth / maxValue * .5
	end

	if division and division > 0 then
		for i = 1, division do
			local s = _getString(2)
			s:SetFormattedText("%d", i * divider)
			s:SetPoint("TOP", ProgressGraph, "BOTTOM", (i * spacer) - halfWidth - correction, -2)

			PxLabels[#PxLabels + 1] = s
		end
	else
		if maxValue and maxValue < divider then
			local s = _getString(2)
			s:SetFormattedText("%d", maxValue)
			s:SetPoint("TOP", ProgressGraph, "BOTTOM", halfWidth - correction, -2)

			PxLabels[#PxLabels + 1] = s
		else
			for i = 1, 10 do
				local s = _getString(2)
				s:SetFormattedText("%d", i)
				s:SetPoint("TOP", ProgressGraph, "BOTTOM", ((i - .5) * maxWidth / 10) - halfWidth, -2)

				PxLabels[#PxLabels + 1] = s
			end
		end
	end

	if maxValue and maxValue > (division * divider) then -- Max value doesn't divide to integers
		local s = _getString(2)
		s:SetFormattedText("%d", maxValue)
		s:SetPoint("TOP", ProgressGraph, "BOTTOM", halfWidth - correction, -2)

		local _, _, _, xOfs = PxLabels[#PxLabels]:GetPoint()
		if s:GetStringWidth() > (halfWidth - correction - xOfs) then -- If the space is smaller than string, hide it
			_releaseString(s, 2)
		else -- There is enough space for the string, show the string
			PxLabels[#PxLabels + 1] = s
		end
	end

	-- Y-axis
	for i = 1, 10 do
		local s = _getString(2)
		s:SetText((i*10).."%")
		s:SetPoint("RIGHT", ProgressGraph, "LEFT", -2, (i * maxHeight / 10) - halfHeight)

		PyLabels[#PyLabels + 1] = s
	end
end

do
	ProgressGraph.bars = {}
	ProgressGraph.Ylines = {}

	for i = 1, 10 do -- Percent lines
		local h = ProgressGraph:CreateTexture(nil, "BACKGROUND")
		h:SetWidth(maxWidth)
		--h:SetHeight(minSize)
		h:SetHeight(1)
		h:SetPoint("CENTER", ProgressGraph, "CENTER", 0, (i * maxHeight / 10) - halfHeight)
		h:SetColorTexture(.5, .5, .5, .5)
		ProgressGraph.Ylines[i] = h
	end

	local yaxis = ProgressGraph:CreateTexture(nil, "FULLSCREEN_DIALOG")
	yaxis:SetWidth(1)
	yaxis:SetHeight(maxHeight + 2)
	yaxis:SetPoint("RIGHT", ProgressGraph, "LEFT")
	yaxis:SetColorTexture(1, 1, 1, 1)
	ProgressGraph.YAxis = yaxis

	local xaxis = ProgressGraph:CreateTexture(nil, "FULLSCREEN_DIALOG")
	xaxis:SetWidth(maxWidth + 2)
	xaxis:SetHeight(1)
	xaxis:SetPoint("TOP", ProgressGraph, "BOTTOM")
	xaxis:SetColorTexture(1, 1, 1, 1)
	ProgressGraph.XAxis = xaxis

	_labelProgressAxes()
end


--------------------------------------------------------------------------------
-- Timer & Snapshotting
--------------------------------------------------------------------------------
local snapshot
local function CombatTimer(self) -- lastPercent
	timer = GetTime() - startTime

	-- Minimap text
	--self.TimerTextRight:SetFormattedText("%02d:%02d.%02d", math.floor(timer / 60), timer % 60, (timer - math.floor(timer)) * 100)
	self.TimerTextRight:SetFormattedText("%02d:%02d.%02d", math_floor(timer / 60), timer % 60, (timer - math_floor(timer)) * 100)

	-- Last HP
	for i = 1, #recUnits do
		if UnitExists(recUnits[i]) then
			local health = (UnitHealth(recUnits[i]) or 0)/(UnitHealthMax(recUnits[i]) or 1)*100
			local guid = UnitGUID(recUnits[i])

			local unitType, _, _, _, _, npcID = strsplit("-", guid)
			npcID = tonumber(npcID) or npcID or unitType

			if npcID and health and health ~= nil and not (health == (health - 1)) then -- Fight the -1.#IND HP ghosts (Eonar)
				previousPercent[npcID] = lastPercent[npcID] or previousPercent[npcID]
				lastPercent[npcID] = health
			end
		end
	end

	-- GraphData snapshoting
	--local graphTime = math.ceil(timer)
	local graphTime = math_ceil(timer)

	if snapshot ~= graphTime then
		for i = 1, #recUnits do
			--if UnitExists(recUnits[i]) then -- Commented out to prevent straight lines on some bosses
				snapshot = graphTime
				local data = graphData.data[snapshot]

				local health = (UnitHealth(recUnits[i]) or 0)/(UnitHealthMax(recUnits[i]) or 1)*100
				local guid, name = UnitGUID(recUnits[i]), (UnitName(recUnits[i]))

				local _, unitType, npcID, spawnID
				if guid then
					unitType, _, _, _, _, npcID, spawnID = strsplit("-", guid)
					npcID = tonumber(npcID) or npcID or unitType
					spawnID = spawnID or unitType
				end

				if npcID and health and health ~= nil and not (health == (health - 1)) then -- Fight the -1.#IND HP ghosts (Eonar)
					--graphData.name[npcID] = graphData.name[npcID] or name
					if (not graphData.name[npcID]) or (graphData.name[npcID] == "Unknown" and name ~= "Unknown") then
						graphData.name[npcID] = name
					end

					data.health[npcID] = data.health[npcID] or {}
					data.health[npcID][spawnID] = data.health[npcID][spawnID] or {}

					data.health[npcID][spawnID] = health
				end

				if not data.buff then -- Save Heroism info
					local unitID = (IsInRaid() and "raid") or "party"
					--for j = 0, GetNumGroupMembers() do
					for j = 0, numGroupMembers do
						local id = (j == 0 and "player") or unitID..j
						if UnitAffectingCombat(id) and not UnitIsDeadOrGhost(id) and not data.buff then
							--for buff = 1, #buffsTable do -- This is supposed to be faster than ipairs according to https://springrts.com/wiki/Lua_Performance
							for k = 1, 40 do
								--if UnitBuff(id, buffsTable[buff]) then -- Changed in BfA, no longer accepts spellName as 2nd input
								--if AuraUtil.FindAuraByName(buffsTable[buff], id) then -- Slow AF, this causes 150-300ms freezes (once every second when we go through this loop) while in encounter...
								local spellName, _, _, _, _, _, _, _, _, spellId = UnitBuff(id, k, "CANCELABLE") -- Try to limit the number of auras we go through with the filters (UnitBuff is UnitAura with HELPFUL)
								if spellName then -- Found some buff, check if it is Heroism-buff
									for buff = 1, #buffsTable do
										if spellName == buffsTable[buff] then
											data.buff = true
											break
										end
									end
								else -- No more buffs found to test on this unit
									break
								end
							end
						elseif data.buff then -- Shouldn't get here, but anything can happen...
							break
						end
					end
				end

				if not phaser then -- Get phase info from DBM if available
					if DBM then
						for j = 1, #DBM.Mods do
							if DBM.Mods[j].encounterId and DBM.Mods[j].encounterId == graphData.info.encounterID then
								phaser = j

								phase = DBM.Mods[phaser].vb.phase or 1
								if (not councilEncounter) and (phase == lastPhase) then -- phaseOrder
									-- councilEncounters usually start with the highest number and work their way down as the fight progresses so this would add extra phase 1 to the stack.
									-- Without this you get no entry at all for first phase if phase == lastPhase and double entry if you add it in without any checks when phase ~= lastPhase
									phaseOrder[#phaseOrder + 1] = phase
								end

								break
							end
						end
					end

				else
					--phase = DBM.Mods[phaser].vb.phase or 1

					if councilEncounter then -- Council Encounter, count bosses left instead of phases.
						if DBM.Mods[phaser].numBoss and DBM.Mods[phaser].numBoss > 0 then
							--phase = (DBM.Mods[phaser].numBoss - DBM.Mods[phaser].vb.bossLeft + 1) or 1 -- +1 to prevent Phase 0
							phase = DBM.Mods[phaser].vb.bossLeft or 1
							isThisCouncilEncounter = true
						end
					else
						phase = DBM.Mods[phaser].vb.phase or 1
					end
				end

				if phase ~= lastPhase then -- Save phase change info
					data.phase = true
					lastPhase = phase
					phaseOrder[#phaseOrder + 1] = phase -- phaseOrder
					Debug("> Progress:", phase, #phaseOrder or "n/a")
				end
			--end
		end
	end
end


--------------------------------------------------------------------------------
-- Draw graph
--------------------------------------------------------------------------------
local nodePool = {}
-- Reset Graphs
local function _resetGraph() -- Reset Kill graphs
	local nodeCount = 0 -- Debug

	-- Hide old graphs for recycling
	for gb in pairs(Graph.buffs) do
		Graph.buffs[gb]:Hide()
		Graph.buffs[gb]:ClearAllPoints()
	end

	for gp in pairs(Graph.phases) do
		Graph.phases[gp]:Hide()
		Graph.phases[gp]:ClearAllPoints()
	end

	for gn = #Graph.nodes, 1, -1 do
		nodeCount = nodeCount + 1 -- Debug

		Graph.nodes[gn]:Hide()
		nodePool[#nodePool + 1] = tremove(Graph.nodes)
	end

	Debug("Reset: %d nodes (Error: %d)", nodeCount, #Graph.nodes) -- Debug

	while #xLabels > 0 do
		_releaseString(tremove(xLabels), 1)
	end
	while #yLabels > 0 do
		_releaseString(tremove(yLabels), 1)
	end
	while #activeMarkers > 0 do
		_releaseMarker(tremove(activeMarkers), 1)
	end
	while #activeMarkerStrings > 0 do
		_releaseString(tremove(activeMarkerStrings), 1)
	end
end

local function _resetPGraph() -- Reset Progress graphs
	-- Hide old graphs for recycling
	for b in pairs(ProgressGraph.bars) do
		ProgressGraph.bars[b]:Hide()
		ProgressGraph.bars[b]:ClearAllPoints()
	end

	while #PxLabels > 0 do
		_releaseString(tremove(PxLabels), 2)
	end
	while #PyLabels > 0 do
		_releaseString(tremove(PyLabels), 2)
	end
	while #PactiveMarkers > 0 do
		_releaseMarker(tremove(PactiveMarkers), 2)
	end
	while #PactiveMarkerStrings > 0 do
		_releaseString(tremove(PactiveMarkerStrings), 2)
	end
end

function f:selectReset(dataType) -- Redirect Reset calls to either Kill or Progress graph reset
	-- 1 = Graph, 2 = PGraph, 3 = Graph + PGraph
	if dataType ~= 2 then -- 1 or 3
		_resetGraph()
	end
	if dataType > 1 then -- 2 or 3
		_resetPGraph()
	end
end

-- Legion non-LibGraph way
function f:LegionDrawGraph(plotData, oldData) -- Draw new graphs
	local nodeCount, skipCount = 0, 0 -- Debug

	local function _GetNode(this, i, index, isRecord) -- self -> this
		nodeCount = nodeCount + 1 -- Debug

		if #nodePool > 0 then
			this.nodes[i] = tremove(nodePool)
			this.nodes[i]:Show()
		else
			this.nodes[i] = this:CreateLine(nil, "OVERLAY") --"BORDER")
			this.nodes[i]:SetThickness(minSize)
		end

		local R, G, B, A = unpack(colorTable[((index - 1) % #colorTable) + 1]) -- Math hack to get rid of the 0 in the modulo, because in Lua tables start from index 1.
		A = isRecord and ((A and A or 1) * 2/5) or (A or 1)
		this.nodes[i]:SetColorTexture(R, G, B, A)

		return this.nodes[i]
	end

	local function _GetBuff(this, i, isRecord) -- self -> this
		this.buffs[i] = this.buffs[i] or this:CreateTexture(nil, "ARTWORK") --"BACKGROUND")

		if isRecord then
			this.buffs[i]:SetColorTexture(1, 0.3, 1, 0.15)
		else
			this.buffs[i]:SetColorTexture(0.3, 0.3, 1, 0.5)
		end

		return this.buffs[i]
	end

	local function _GetPhase(this, i, isRecord) -- self -> this
		this.phases[i] = this.phases[i] or this:CreateTexture(nil, "ARTWORK") --"BACKGROUND")

		local A = isRecord and .15 or .5
		this.phases[i]:SetColorTexture(1, 1, .3, A)

		return this.phases[i]
	end

	_resetGraph()

	local scale = 1 -- _G.UIParent:GetEffectiveScale()
	local maxX = math.max((oldData and oldData.data) and #oldData.data or timeLimit, plotData.data and #plotData.data or timeLimit)

	-- Some times there are some gaps left behind by the _cleanDB() usage and we try to fix those with this
	if oldData and oldData.info and oldData.info.timer and math.ceil(oldData.info.timer) > maxX then
		for i in pairs(oldData.data) do
			if i > maxX then
				maxX = i
			end
		end
	end
	if plotData and plotData.info and plotData.info.timer and math.ceil(plotData.info.timer) > maxX then
		for i in pairs(plotData.data) do
			if i > maxX then
				maxX = i
			end
		end
	end

	local maxY = 100
	local buffNow = 0
	local phaseNow = 0
	local nodeNow = 0
	local Xnow = {}
	local Ynow = {}
	local indexTable = {}
	local z = 1
	local labelsTable = {} -- Hack to get markers for same named NPCs with different npcID
	if plotData and plotData.name then
		for key in pairs(plotData.name) do
			if not indexTable[key] then
				if RaidBosses[key] then -- Boss, bump everything to get bosses nice colors
					for k, v in pairs(indexTable) do
						indexTable[k] = v + 1
					end
					indexTable[key] = 1
				else
					indexTable[key] = z
				end
				z = z + 1
			end
		end
	end
	if oldData and oldData.name then
		for key in pairs(oldData.name) do
			if not indexTable[key] then
				if RaidBosses[key] then -- Boss, bump everything to get bosses nice colors
					for k, v in pairs(indexTable) do
						indexTable[k] = v + 1
					end
					indexTable[key] = 1
				else
					indexTable[key] = z
				end
				z = z + 1
			end
		end
	end


	local function _plot(dataPoints, numPoints, isRecord)
		Debug("dataPoints:", #dataPoints.data, numPoints)
		if not dataPoints or not dataPoints.data then
			-- For some reason the dataPoints dataset is empty, this can happen to some of the old encounters (Classic and TBC)
			Debug("!!! Empty dataPoints-set")
			local m = _getMarker(1)
			m:SetColorTexture(255, 0, 0, 255)
			activeMarkers[#activeMarkers + 1] = m

			local s = _getString(1)
			s:SetText(isRecord and "OLD DATASET IS EMPTY" or "DATASET IS EMPTY")
			activeMarkerStrings[#activeMarkerStrings + 1] = s

			return
		end

		local nilHealthTables = {}
		local nilDataPoints = {}
		local firstNilHealth, lastNilHealth
		local firstNilDataPoint, lastNilDataPoint

		--for x = 1, #dataPoints.data do
		for x = 1, numPoints do -- Don't stop on the gaps in the dataPoints.data
			if dataPoints.data[x] then
				if dataPoints.data[x].buff then
					Xnow.buff = Xnow.buff or (x - 1)
					if x ~= Xnow.buff and (x / maxX * maxWidth) < maxWidth then
						buffNow = buffNow + 1
						local buff = _GetBuff(Graph, buffNow, isRecord)
						buff:SetPoint("BOTTOMLEFT", Graph, "BOTTOMLEFT", x / maxX * maxWidth, 0)
						local width = (x - Xnow.buff) / maxX * maxWidth
						width = ((x / maxX * maxWidth + width) > maxWidth) and width - ((x / maxX * maxWidth + width) - maxWidth) or width or 1
						buff:SetSize(width, maxHeight)

						buff:Show()
						Xnow.buff = x
					end
				else
					Xnow.buff = nil
				end

				--if dataPoints.data[x].phase then
				if dataPoints.data[x].phase and not dataPoints.info.councilEncounter then -- Don't draw phases on Council Encounters
					phaseNow = phaseNow + 1
					local phaseChange = _GetPhase(Graph, phaseNow, isRecord)
					phaseChange:SetPoint("BOTTOMLEFT", Graph, "BOTTOMLEFT", x / maxX * maxWidth, 0)
					phaseChange:SetSize(minSize, maxHeight)

					phaseChange:Show()
				end

				local needLabel
				if dataPoints.data[x].health then
					for npcID, spawn in pairs(dataPoints.data[x].health) do
						needLabel = true

						for spawnID, y in pairs(spawn) do
							if spawnID and y then -- Maybe this removes garbage
								if type(y) == "table" then break end -- Sometimes y is empty table (thanks Eonar)

								Xnow[npcID..spawnID] = Xnow[npcID..spawnID] or (x - 1) or 0
								Ynow[npcID..spawnID] = Ynow[npcID..spawnID] or y or 100

								if x ~= Xnow[npcID..spawnID] then
									local startX = Xnow[npcID..spawnID] / maxX * maxWidth
									local startY = Ynow[npcID..spawnID] / maxY * maxHeight
									startX = startX < maxWidth and startX or maxWidth
									startY = startY < maxHeight and startY or maxHeight
									local width = (x - Xnow[npcID..spawnID]) / maxX * maxWidth
									local height = abs(y - Ynow[npcID..spawnID]) / maxY * maxHeight

									-- Line is a real line instead of a single point (aka 0 distance line), or last data-point
									--if sqrt((width * width) + (height * height)) >= 1 then -- 809 / 1038
									if math.sqrt((width * width) + (height * height)) >= minSize or x == #dataPoints.data then -- 442 / 536
									--if (width >= 1) or (height >= 1) then -- 809 / 1038
									--if (width >= minSize) or (height >= minSize) or x == #dataPoints.data then -- 406 / 534
										local deltaY = (Ynow[npcID..spawnID] > y) and true or false
										height = deltaY and -height or height
										local endX = (startX + width) > maxWidth and maxWidth or (startX + width)
										local endY = (startY + height) > maxHeight and maxHeight or (startY + height)

										nodeNow = nodeNow + 1
										local node = _GetNode(Graph, nodeNow, indexTable[npcID], isRecord)
										node:SetStartPoint("BOTTOMLEFT", Graph, startX * scale, startY * scale)
										node:SetEndPoint("BOTTOMLEFT", Graph, endX * scale, endY * scale)

										node:Show()
										Xnow[npcID..spawnID] = x
										Ynow[npcID..spawnID] = y

										--if width >= 10 * minSize and height >= 10 * minSize then -- Hide over sized nodes (like when bosses hide or are swapped for longer periods)
										if width >= 10 / maxX * maxWidth and height >= 10 / maxY * maxHeight then -- Hide over sized nodes (like when bosses hide or are swapped for longer periods)
											node:Hide()
										end
									else
										skipCount = skipCount + 1
										--Debug("> Skip @", x, width, height)
									end
								end
							else
								needLabel = false
							end
						end

						if needLabel then -- Don't iterate if we already know we don't need label
							for k = 1, #activeMarkerStrings do
								if activeMarkerStrings[k]:GetText() == dataPoints.name[npcID] then
									needLabel = false
									break
								end
							end
						end
						if (not needLabel) and (not labelsTable[npcID]) then -- Hack to get markers for same named NPCs with different npcID
								Debug("> Same name, different npcID:", npcID, dataPoints.name[npcID] or "Unknown")
								needLabel = true
						end
						if needLabel then -- Get label if we still need one
							local R, G, B, A = unpack(colorTable[((indexTable[npcID] - 1) % #colorTable) + 1]) -- Math hack to get rid of the 0 in the modulo, because in Lua tables start from index 1.

							local m = _getMarker(1)
							m:SetColorTexture(R, G, B, A*4/5)
							activeMarkers[#activeMarkers + 1] = m

							local s = _getString(1)
							s:SetText(dataPoints.name[npcID] or "Unknown")
							activeMarkerStrings[#activeMarkerStrings + 1] = s

							labelsTable[npcID] = dataPoints.name[npcID] or "Unknown"
						end
					end

					if lastNilHealth then -- nil-gap closed
						if firstNilHealth == lastNilHealth then -- missing only one point
							nilHealthTables[#nilHealthTables + 1] = firstNilHealth
						else -- a real gap
							nilHealthTables[#nilHealthTables + 1] = string.format("%d-%d", firstNilHealth, lastNilHealth)
						end
						firstNilHealth = nil
						lastNilHealth = nil
					end
				else
					--Debug("> nil health table @", x, tostring(isRecord))
					--nilHealthTables[#nilHealthTables + 1] = x
					if firstNilHealth then -- nil-gap going, update the possible end
						lastNilHealth = x
					else -- Open new nil-gap
						firstNilHealth = x
						lastNilHealth = x
					end
				end

				if lastNilDataPoint then -- nil-gap closed
					if firstNilDataPoint == lastNilDataPoint then -- missing only one point
						nilDataPoints[#nilDataPoints + 1] = firstNilDataPoint
					else -- a real gap
						nilDataPoints[#nilDataPoints + 1] = string.format("%d-%d", firstNilDataPoint, lastNilDataPoint)
					end
					firstNilDataPoint = nil
					lastNilDataPoint = nil
				end
			else
				--Debug("> nil @", x, tostring(isRecord))
				--nilDataPoints[#nilDataPoints + 1] = x
				if firstNilDataPoint then -- nil-gap going, update the possible end
					lastNilDataPoint = x
				else -- Open new nil-gap
					firstNilDataPoint = x
					lastNilDataPoint = x
				end
			end
		end

		-- Tie the lose ends if we end up with open nils
		if lastNilHealth then
			if firstNilHealth == lastNilHealth then -- missing only one point
				nilHealthTables[#nilHealthTables + 1] = firstNilHealth
			else -- a real gap
				nilHealthTables[#nilHealthTables + 1] = string.format("%d-%d", firstNilHealth, lastNilHealth)
			end
			firstNilHealth = nil
			lastNilHealth = nil
		end
		if lastNilDataPoint then
			if firstNilDataPoint == lastNilDataPoint then -- missing only one point
				nilDataPoints[#nilDataPoints + 1] = firstNilDataPoint
			else -- a real gap
				nilDataPoints[#nilDataPoints + 1] = string.format("%d-%d", firstNilDataPoint, lastNilDataPoint)
			end
			firstNilDataPoint = nil
			lastNilDataPoint = nil
		end

		if #nilHealthTables > 0 then
			Debug("> nil health table(s) @", table.concat(nilHealthTables, ", "), tostring(isRecord))
		end
		if #nilDataPoints > 0 then
			Debug("> nil data-point(s) @", table.concat(nilDataPoints, ", "), tostring(isRecord))
		end
	end

	if oldData then
		_plot(oldData, maxX, true)
		wipe(Xnow)
		wipe(Ynow)
	end
	_plot(plotData, maxX, false)

	for i = 1, #activeMarkers do -- Resort labels, moved this here because sometimes they were processed in wrong order and wont be anchored correctly
		local m = activeMarkers[i]
		local s = activeMarkerStrings[i]
		if i == 1 then
			m:SetPoint("TOPLEFT", Graph, "BOTTOMLEFT", 0, -20)
		else
			m:SetPoint("LEFT", activeMarkerStrings[i - 1], "RIGHT", 10, 0)
		end
		s:SetPoint("LEFT", activeMarkers[i], "RIGHT", 2, 0)
	end

	_labelAxes(maxX)

	Frame:Show()

	Debug("Graph: %d nodes (Pool: %d, Skips: %d)", nodeCount, #nodePool, skipCount) -- Debug
end

function f:DrawProgressBars(data, isCouncilEncounter) -- Draw bars for kill progress
	_resetPGraph()

	if not data then
		_labelProgressAxes()
		return
	end

	local maxX = math.max(1, #data)
	--local Xnow = 0
	local indexTable = {}
	local phases = {}

	local function _GetBar(this, i, fightPhase) -- self -> this
		this.bars[i] = this.bars[i] or this:CreateTexture(nil, "ARTWORK") --"BACKGROUND")

		local fp = math.floor(fightPhase)
		local R, G, B, A, scaler
		R, G, B, A = unpack(colorTable[((fp - 1) % #colorTable) + 1]) -- Math hack to get rid of the 0 in the modulo, because in Lua tables start from index 1.

		if fightPhase ~= fp then
			scaler = .5 --2/5
		else
			scaler = .75 --4/5
		end
		R = R * scaler
		G = G * scaler
		B = B * scaler
		A = A or 1
		this.bars[i]:SetColorTexture(R, G, B, A)

		if not indexTable[fightPhase] then
			indexTable[fightPhase] = { R, G, B, A }
		end

		return this.bars[i]
	end

	local function _plot(dataPoints)
		for x = 1, #dataPoints do
			local sample = dataPoints[x]
			local bar = _GetBar(ProgressGraph, x, sample["phase"])
			-- Should be 1, but sometimes because of scaling the gap disappears and 1.2 is too much
			bar:SetPoint("BOTTOMLEFT", ProgressGraph, "BOTTOMLEFT", (x - 1) / maxX * maxWidth + 1, 0) -- Put small gap between bars
			--local width = (x - Xnow) / maxX * maxWidth - 1 -- Put small gap between bars
			local width = maxWidth / maxX - 1 -- Put small gap between bars
			local height = math.min(sample["percent"] / 100 * maxHeight, maxHeight)
			bar:SetSize(width, height)
			bar:Show()
			--Xnow = x

			local newPhase = true
			for i = 1, #phases do
				if sample["phase"] == phases[i] then
					--Debug("Old Phase:", sample["phase"])
					newPhase = false
					break
				end
			end
			if newPhase then
				--Debug("New Phase:", sample["phase"])
				phases[#phases + 1] = sample["phase"]
			end
		end
	end

	_plot(data)

	if isCouncilEncounter then -- Reverse sort, less bosses left is better progress.
		sort(phases, function(a, b) return a > b end)
	else -- Normal sort, higher phase number is better progress
		sort(phases)
	end
	for i = 1, #phases do -- Do phase markers
		local R, G, B, A = unpack(indexTable[phases[i]])

		--local m = _getPMarker()
		local m = _getMarker(2)
		m:SetColorTexture(R, G, B, A)
		PactiveMarkers[#PactiveMarkers + 1] = m

		--local s = _getPString()
		local s = _getString(2)
		if isCouncilEncounter then -- Council Encounter, count bosses left instead of phases.
			s:SetText(phases[i].." bosses left" or "Unknown")
		else
			s:SetText("Phase "..phases[i] or "Unknown")
		end
		PactiveMarkerStrings[#PactiveMarkerStrings + 1] = s

		if i == 1 then
			m:SetPoint("TOPLEFT", ProgressGraph, "BOTTOMLEFT", 0, -20)
		else
			m:SetPoint("LEFT", PactiveMarkerStrings[i - 1], "RIGHT", 10, 0)
		end
		s:SetPoint("LEFT", PactiveMarkers[i], "RIGHT", 2, 0)
	end

	_labelProgressAxes(maxX)

	if not Frame:IsShown() then -- This should be visible from the DrawGraph()
		Frame:Show()
	end
end

-- Redirect Draw calls to right place
function f:selectDrawing(dataType, ...)
	if dataType == 1 then
		self:LegionDrawGraph(...)
	else
		self:DrawProgressBars(...)
	end
end

-- Process data after ENCOUNTER_END for Drawing
function f:ProcessData()
	local function deepcopy(orig) -- http://lua-users.org/wiki/CopyTable
		local orig_type = type(orig)
		local copy

		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[deepcopy(orig_key)] = deepcopy(orig_value)
			end
			--setmetatable(copy, deepcopy(getmetatable(orig))) -- No need for this
		else -- number, string, boolean, etc
			copy = orig
		end

		return copy
	end
	local function _saveBosses(gData) -- graphData for graphData.info and graphData.data
		local gdInfo = gData.info
		local gdData = gData.data
		local gdName = gData.name

		if not gdInfo.difficultyID or not recordThis[gdInfo.difficultyID] then return end

		if gdInfo then -- Boss' and adds npcIDs
			for i = 1, #gdData do
				if gdData[i] and gdData[i].health then -- Check if there is any data
					for npcID in pairs(gdData[i].health) do
						if npcID and npcID > 0 and not (RaidBosses[npcID] or BossAdds[npcID]) then -- Not known Boss or Boss minion
							if not bossDB[gdInfo.instanceID] then
								bossDB[gdInfo.instanceID] = { name = (EJ_GetInstanceInfo(gdInfo.instanceID)) }
							end
							if not bossDB[gdInfo.instanceID][gdInfo.encounterID] then
								bossDB[gdInfo.instanceID][gdInfo.encounterID] = { name = gdInfo.encounterName }
							end
							if (not bossDB[gdInfo.instanceID][gdInfo.encounterID][npcID]) or (bossDB[gdInfo.instanceID][gdInfo.encounterID][npcID] == "Unknown" and tostring(gdName[npcID]) ~= "Unknown") then -- new npcID
								bossDB[gdInfo.instanceID][gdInfo.encounterID][npcID] = tostring(gdName[npcID])
								Debug("> New NPC: %s (%d)", tostring(gdName[npcID]), tonumber(npcID))
							--else -- Already saved to the bossDB
							--	Debug("> Found already saved NPC:", tostring(gdName[npcID]))
							end
						--else -- Known Boss or Boss minion or no npcID
						--	Debug("> Known NPC: %s (%d)", tostring(gdName[npcID]), tonumber(npcID))
						end
					end
				end
			end
		end
	end

	if not graphData.info or not graphData.info.timer or graphData.info.timer < timeLimit then
		self:selectReset(3)

		_saveBosses(graphData)
		Frame:SetStatusText(string.format("No combat data or combat time was less than %d seconds.", timeLimit))
		if not InCombatLockdown() then
			Frame:Show()
		end

		return
	end

	-- Check if the instanceID needs fixing
	if instanceIDFixes[graphData.info.instanceID] and instanceIDFixes[graphData.info.instanceID][graphData.info.encounterID] then
		Debug("!!! Fixing instanceID:", graphData.info.instanceID, "->", instanceIDFixes[graphData.info.instanceID][graphData.info.encounterID])
		graphData.info.instanceID = instanceIDFixes[graphData.info.instanceID][graphData.info.encounterID]
	end

	local tempTable = {}
	local exitState = 0 -- 0 = no previous record, 1 = old record kept, 2 = new record
	local recordString = ""
	local info = graphData.info

	local knownBoss = false
	if RaidEncounterIDs[info.instanceID] and RaidEncounterIDs[info.instanceID][info.encounterID] then
		knownBoss = true
		Debug("knownBoss")
	else
		Debug("not knownBoss")
	end

	-- This causes gaps in some cases, but I have tried to mitigate it in the plotting.
	_cleanDB(graphData.data) -- Remove garbage

	Debug("Data nodes:", #graphData.data)

	_saveBosses(graphData)

	--Testing above stuff in LFR, prevent below stuff from going on
	if not info.difficultyID or not recordThis[info.difficultyID] then return end -- Debug and Testing
	Debug("Raid!", info.difficultyID)

	progressDB[info.instanceID] = progressDB[info.instanceID] or {}
	progressDB[info.instanceID][info.encounterID] = progressDB[info.instanceID][info.encounterID] or {}
	progressDB[info.instanceID][info.encounterID][info.difficultyID] = progressDB[info.instanceID][info.encounterID][info.difficultyID] or {}

	dataDB[info.instanceID] = dataDB[info.instanceID] or {}
	dataDB[info.instanceID][info.encounterID] = dataDB[info.instanceID][info.encounterID] or {}
	dataDB[info.instanceID][info.encounterID][info.difficultyID] = dataDB[info.instanceID][info.encounterID][info.difficultyID] or {}
	local dbinfo = dataDB[info.instanceID][info.encounterID][info.difficultyID].info or {}

	if info.endStatus == 1 then -- Kill
		info.bestTry = 0
		info.bestPhase = phase or 1

		if dbinfo and dbinfo.timer and dbinfo.timer > info.timer and dbinfo.endStatus == 1 then
			-- New record!
			Debug("New record!")
			exitState = 2

			local delta = abs(dbinfo.timer - info.timer)
			recordString = string.format("|cff00ff00New record!|r -%02d:%02d.%02d (%d player)", math.floor(delta / 60), delta % 60, (delta - math.floor(delta)) * 100, dbinfo.raidSize)

			tempTable = deepcopy(dataDB[info.instanceID][info.encounterID][info.difficultyID])
			dataDB[info.instanceID][info.encounterID][info.difficultyID] = deepcopy(graphData)
		elseif dbinfo and dbinfo.timer and dbinfo.timer <= info.timer and dbinfo.endStatus == 1 then
			-- Not a record.
			Debug("Old record kept.")
			exitState = 1

			local delta = abs(dbinfo.timer - info.timer)
			recordString = string.format("Old record +%02d:%02d.%02d (%d player)", math.floor(delta / 60), delta % 60, (delta - math.floor(delta)) * 100, dbinfo.raidSize)

			if not dbinfo.bestTry then -- Failsafe to update older data
				dbinfo.bestTry = info.bestTry
			end
			if not dbinfo.bestPhase then -- Failsafe to update older data
				dbinfo.bestPhase = info.bestPhase
			end
		elseif dbinfo and (not dbinfo.endStatus or dbinfo.endStatus == 0) then
			-- First kill!
			Debug("First kill!")
			exitState = 0

			recordString = "|cff00ff00First Kill!|r"

			dataDB[info.instanceID][info.encounterID][info.difficultyID] = deepcopy(graphData)
			progressDB[info.instanceID][info.encounterID][info.difficultyID][#progressDB[info.instanceID][info.encounterID][info.difficultyID] + 1] = { combatTime = info.timer, percent = info.bestTry, phase = info.bestPhase }
		else
			Debug("WUT?: Kill")
		end
	else
		-- Get wipe percent and phase
		local i, amount, numBosses = 0, 0, 0
		local councilTable, councilHealth = {}, {}

		if graphData and graphData.data and #graphData.data then
			while amount == 0 do
				if graphData.data[#graphData.data - i].health then
					for npcID, HPdata in pairs(graphData.data[#graphData.data - i].health) do
						for _, value in pairs(HPdata) do
							if (knownBoss and RaidBosses[npcID]) or -- Include bosses only
							(not BossAdds[npcID]) then -- Exlude non-boss adds because it can be boss not saved yet
								Debug("knownBoss: %s (%s)", knownBoss and "true" or "false", tostring(graphData.name[npcID]))
								Debug("> %.3f / %.3f / %.3f", value, lastPercent[npcID] or 99999, previousPercent[npcID] or 99999)

								local accurateValue
								if lastPercent[npcID] or previousPercent[npcID] then -- Check if we gave results from frameUpdate
									local lHealth = lastPercent[npcID]
									local pHealth = previousPercent[npcID]
									if lHealth and lHealth <= value and lHealth > 0 and not (lHealth == (lHealth - 1)) then
										accurateValue = lHealth
									elseif pHealth and pHealth <= value and pHealth > 0 and not (pHealth == (pHealth - 1)) then
										accurateValue = pHealth
									end
								end

								numBosses = numBosses + 1
								if accurateValue and accurateValue <= value and accurateValue > 0 then -- Data from last frameUpdate was better
									if info.councilEncounter then -- In Council Encounter, only the lowest HP npc matters
										if not councilTable[npcID] or councilTable[npcID] > accurateValue then
											councilTable[npcID] = accurateValue
										end
									end
									amount = amount + accurateValue
								else -- Use latest snapshot values
									if info.councilEncounter then -- In Council Encounter, only the lowest HP npc matters
										if not councilTable[npcID] or councilTable[npcID] > value then
											councilTable[npcID] = value
										end
									end
									amount = amount + value
								end
							end
						end
					end
				end
				i = i + 1

				if i >= #graphData.data then
					Debug("Breaking 'while' %d / %d / %d / %d", i, #graphData.data, amount, numBosses)
					break
				end
			end
		end

		for npcID, name in pairs(graphData.name) do -- List all new npcID's
			if not RaidBosses[npcID] and not BossAdds[npcID] then
				-- New Boss or add found
				Debug("New NPC: [%d] = \"%s\", -- %s", npcID, name, info.encounterName)
			end
		end

		-- == COUNCIL ENCOUNTER START == --
		--[[
			Trying to wrap my head around this council style fight progress

			Phase 1
			50 % <-- #1
			100 %

			Phase 2
			0 %
			50 % <-- #2
			100 %

			Phase 3
			0 %
			0 %
			50 % <-- #3
			100 %

			Phase 4
			0 %
			0 %
			0 %
			50 % <-- #4
		]]

		for _, npcHP in pairs(councilTable) do -- Put HP-values to table, sort it and pick the 'phase'th line
			councilHealth[#councilHealth + 1] = npcHP
		end
		--sort(councilHealth, function(a, b) return a > b end) -- Reverse sort
		sort(councilHealth)

		for bossNum = 1, #councilHealth do
			Debug("Council:", bossNum, _round(councilHealth[bossNum], 3))
		end
		--for key, value in ipairs(councilHealth) do
		--	Debug("Council:", key, value)
		--end
		-- == COUNCIL ENCOUNTER END == --

		--local wpercent = info.councilEncounter and (councilHealth[phase] and councilHealth[phase] or (amount / math.max(1, numBosses))) or (amount / math.max(1, numBosses)) -- Don't divide with 0
		-- Council Encounter: Pick first item in the table since there are no zeroes anymore, because I fixed some other bugs unknowingly?
		local wpercent = info.councilEncounter and (councilHealth[1] and councilHealth[1] or (amount / math.max(1, numBosses))) or (amount / math.max(1, numBosses)) -- Don't divide with 0
		local wphase = phase or 1

		-- These won't be saved unless it is record so we can set them here
		info.bestTry = wpercent or 100
		info.bestPhase = wphase

		if dbinfo and dbinfo.endStatus and dbinfo.endStatus == 1 then
			-- Wipe on farm boss.
			Debug("Wipe.")
			exitState = 1

			local oldPhase = dbinfo.bestPhase or 1

			if info.councilEncounter then -- Council Encounter, count bosses left instead of phases.
				recordString = string.format("Wipe at %d bosses left %.2f%%", wphase, wpercent)
			elseif oldPhase > 1 then
				recordString = string.format("Wipe at Phase %d %.2f%%", wphase, wpercent)
			else
				recordString = string.format("Wipe at %.2f%%", wpercent)
			end
		else
			-- Progress wipe.
			Debug("Progress wipe.")
			exitState = 0

			progressDB[info.instanceID][info.encounterID][info.difficultyID][#progressDB[info.instanceID][info.encounterID][info.difficultyID] + 1] = { combatTime = info.timer, percent = info.bestTry, phase = info.bestPhase }

			if
				dbinfo and (dbinfo.bestTry and dbinfo.bestPhase) and dbinfo.endStatus == 0
				--and (wphase > dbinfo.bestPhase or (wphase == dbinfo.bestPhase and wpercent < dbinfo.bestTry)) then
				and (
					(info.councilEncounter and wphase < dbinfo.bestPhase) or
					(info.ignorePhasesEncounter and wpercent < dbinfo.bestTry) or
					(
						(not info.councilEncounter and not info.ignorePhasesEncounter) and
							(wphase > dbinfo.bestPhase or
							wphase == dbinfo.bestPhase and wpercent < dbinfo.bestTry)
					)
				)
			then
				-- New record wipe!
				Debug("New record!")

				local oldPercent = dbinfo.bestTry or 100
				local oldPhase = dbinfo.bestPhase or 1

				if info.councilEncounter then -- Council Encounter, count bosses left instead of phases.
					recordString = string.format("Wipe at %d bosses left %.2f%% - |cff00ff00New Record!|r Previous best: %d bosses left %.2f%% (%d player)", wphase, wpercent, oldPhase, oldPercent, dbinfo.raidSize)
				elseif oldPhase > 1 or wphase > 1 then
					recordString = string.format("Wipe at Phase %d %.2f%% - |cff00ff00New Record!|r Previous best: Phase %d %.2f%% (%d player)", wphase, wpercent, oldPhase, oldPercent, dbinfo.raidSize)
				else
					recordString = string.format("Wipe at %.2f%% - |cff00ff00New Record!|r Previous best: %.2f%% (%d player)", wpercent, oldPercent, dbinfo.raidSize)
				end

				tempTable = deepcopy(dataDB[info.instanceID][info.encounterID][info.difficultyID])
				dataDB[info.instanceID][info.encounterID][info.difficultyID] = deepcopy(graphData)

				if type(tempTable) == "table" then -- Failsafe to test older data
					exitState = 2 -- Upgrade for comparison
				end
			elseif dbinfo and (dbinfo.bestTry and dbinfo.bestPhase) and dbinfo.endStatus == 0 then
				-- No record.
				Debug("Old record kept.")
				exitState = 1

				local oldPercent = dbinfo.bestTry or 100
				local oldPhase = dbinfo.bestPhase or 1

				if info.councilEncounter then -- Council Encounter, count bosses left instead of phases.
					recordString = string.format("Wipe at %d bosses left %.2f%% - Best try: %d bosses left %.2f%% (%d player)", wphase, wpercent, oldPhase, oldPercent, dbinfo.raidSize)
				elseif oldPhase > 1 or wphase > 1 then
					recordString = string.format("Wipe at Phase %d %.2f%% - Best try: Phase %d %.2f%% (%d player)", wphase, wpercent, oldPhase, oldPercent, dbinfo.raidSize)
				else
					recordString = string.format("Wipe at %.2f%% - Best try: %.2f%% (%d player)", wpercent, oldPercent, dbinfo.raidSize)
				end
			elseif dbinfo and (not dbinfo.endStatus or dbinfo.endStatus == 0) then
				-- First wipe!
				Debug("First wipe!")

				if info.councilEncounter then -- Council Encounter, count bosses left instead of phases.
					recordString = string.format("Wipe at %d bosses left %.2f%% - |cff00ff00First try!|r", wphase, wpercent)
				elseif wphase > 1 then
					recordString = string.format("Wipe at Phase %d %.2f%% - |cff00ff00First try!|r", wphase, wpercent)
				else
					recordString = string.format("Wipe at %.2f%% - |cff00ff00First try!|r", wpercent)
				end

				dataDB[info.instanceID][info.encounterID][info.difficultyID] = deepcopy(graphData)
			else
				Debug("WUT?: Wipe")
			end
		end
	end

	--if exitState >= 1 then
		list:SetTree(_UpdateTree(dataDB))

		if list.localstatus and list.localstatus.groups then -- Open the menus up to the right encounter
			list.localstatus.groups[info.instanceID] = true
			list.localstatus.groups[info.instanceID .. "\001" .. info.encounterID] = true
		end
		list:SelectByPath(info.instanceID, info.encounterID, info.difficultyID)

		--list:SelectByValue(info.instanceID.."\001"..info.encounterID.."\001"..info.difficultyID)
		--list:RefreshTree(true)
	--end

	Frame:SetStatusText(string.format("%s on %s %s (%d player) (%02d:%02d.%02d) - %s", info.endStatus == 1 and "Kill" or "Wipe", GetDifficultyInfo(info.difficultyID) or difficultyTable[info.difficultyID] or "unknown difficulty", info.encounterName, info.raidSize, math.floor(info.timer/60), info.timer % 60, (info.timer - math.floor(info.timer)) * 100, recordString))

	Debug("Send to Drawing:", exitState, "(", tostring(isThisCouncilEncounter), " / ", tostring(info.councilEncounter), ")")
	if exitState > 1 then -- New Record
		self:selectDrawing(1, graphData, tempTable)
	elseif exitState > 0 then -- Old Record / Wipe with Old Record
		self:selectDrawing(1, graphData, dataDB[info.instanceID][info.encounterID][info.difficultyID])
	else -- First kill or Wipe without Old Record
		self:selectDrawing(1, graphData)
	end
	-- Draw ProgressBars
	self:selectDrawing(2, progressDB[info.instanceID][info.encounterID][info.difficultyID], info.councilEncounter)
	Graph:Show()
	ProgressGraph:Hide()


	Debug("Phases:", table.concat(phaseOrder, " -> "))
	local phaseCount = {}
	local multipleSamePhases = false
	for c = 1, #phaseOrder do
		if not phaseCount[phaseOrder[c]] then
			phaseCount[phaseOrder[c]] = 1
		else
			phaseCount[phaseOrder[c]] = phaseCount[phaseOrder[c]] + 1
			multipleSamePhases = true
		end
	end
	if multipleSamePhases then
		local phaseString = ""
		for k, v in pairs(phaseCount) do
			if phaseString == "" then
				phaseString = k .. " = " .. v
			else
				phaseString = phaseString .. ", " .. k .. " = " .. v
			end
		end
		Debug("Phase Counts:", phaseString)
	end


	local inGroup, numGuildPresent, numGuildRequired, xpMultiplier = InGuildParty()
	Debug("GuildCheck: %s (%d%% %d/%d)", tostring(inGroup), numGuildPresent / math.max(1, numGroupMembers) * 100, numGuildPresent, numGroupMembers)
	if inGroup then -- If in guild group, save roster
		-- Save roster to progressDB
		progressDB[info.instanceID]["roster"] = progressDB[info.instanceID]["roster"] or {}

		local rosterInfo = progressDB[info.instanceID]["roster"]
		--local baseUID = (IsInRaid() and "raid") or "party"
		local n, u, s = 0, 0, 0 -- New, Updated, Skipped

		--for i = 0, GetNumGroupMembers() do
		--for i = 0, numGroupMembers do
		for i = 1, numGroupMembers do
			--[[
			local unitID = (i == 0 and "player") or baseUID..i
			local name = GetUnitName(unitID, true)
			local rosterName = GetRaidRosterInfo(i)
			]]
			local name = GetRaidRosterInfo(i)

			--local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo(unitID)
			local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo(name)
			guildName = guildRealm and guildName .. "-" .. guildRealm or guildName

			if not rosterInfo[name] and not ignoredNames[name] then -- New entry
				rosterInfo[name] = {
					["firstSeen"] = info.timestamp,
					["lastSeen"] = info.timestamp,
					["guildName"] = guildName,
					["guildRank"] = guildRankName,
					["guildRankIndex"] = guildRankIndex
				}
				n = n + 1
			else -- Update old entry
				--if UnitIsVisible(unitID) then -- Unit is within 100-yard radius and we should have right information
				if UnitIsVisible(name) and not ignoredNames[name] then -- Unit is within 100-yard radius and we should have right information
					-- Update lastSeen
					rosterInfo[name]["lastSeen"] = info.timestamp

					-- Check guildRank needs updating
					if rosterInfo[name]["guildRank"] ~= guildRankName then
						rosterInfo[name]["guildRank"] = guildRankName
						rosterInfo[name]["guildRankIndex"] = guildRankIndex
					elseif not rosterInfo[name]["guildRankIndex"] then
						rosterInfo[name]["guildRankIndex"] = guildRankIndex
					end

					-- Check if guildName has changed or there weren't guildName previously but now there is -> Save the changes
					if (rosterInfo[name]["guildName"] and rosterInfo[name]["guildName"] ~= guildName) or (guildName and not rosterInfo[name]["guildName"]) then
						rosterInfo[name]["guildHistory"] = rosterInfo[name]["guildHistory"] or {}
						rosterInfo[name]["guildHistory"][#rosterInfo[name]["guildHistory"] + 1] = {
							info.timestamp,
							rosterInfo[name]["guildName"],
							guildName
						}
						rosterInfo[name]["guildName"] = guildName
					end
					u = u + 1
				else -- Not within 100-yard radius, we might not have right information, better not to update
					--Debug("! Unit %s (%s) is not in range?", name, unitID)
					Debug("! Unit %s (%d) is not in range or ignored name?", name, i)
					s = s + 1
				end
			end
		end
		Debug("Comp N: %d, U: %d, S: %d, T: %d/%d (%d).", n, u, s, (n + u), (n + u + s), (n + u) / (n + u + s) * 100)
	end
end


--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------
function f:ADDON_LOADED(event, addon)
	if addon ~= ADDON_NAME then return end
	self:UnregisterEvent("ADDON_LOADED")

	if type(FightRecorderData) ~= "table" then FightRecorderData = {} end
	if type(FightRecorderBossData) ~= "table" then FightRecorderBossData = {} end
	if type(FightRecorderProgressData) ~= "table" then FightRecorderProgressData = {} end
	dataDB = FightRecorderData
	bossDB = FightRecorderBossData
	progressDB = FightRecorderProgressData
	list:SetTree(_UpdateTree(dataDB))
	_initDB(graphData, dataDefaults)
	setmetatable(graphData.data, graphDataMetaTable)

	if IsLoggedIn() then
		self:PLAYER_LOGIN()
	else
		self:RegisterEvent("PLAYER_LOGIN")
	end

	Debug(event)
	self.ADDON_LOADED = nil
end

function f:PLAYER_LOGIN(event)
	self:UnregisterEvent("PLAYER_LOGIN")

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ENCOUNTER_START")
	self:RegisterEvent("ENCOUNTER_END")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")

	self.PLAYER_LOGIN = nil
end

function f:PLAYER_ENTERING_WORLD(event)
	self.GROUP_ROSTER_UPDATE()

	if IsEncounterInProgress() then
		Debug("Entered encounter in progress, starting timer.")

		startTime = GetTime()
		timer = 0
		self:SetScript("OnUpdate", CombatTimer)

		--self:UnregisterEvent("GROUP_ROSTER_UPDATE")
	end
end

function f:ENCOUNTER_START(event, encounterID, encounterName, difficultyID, raidSize)
	Debug("ES:", event, encounterID, encounterName, difficultyID, raidSize)

	local now = GetTime()
	if now - jammer < jammerThreshold then -- Don't start recording twice within threshold time.
		Debug("Jammered.")
		return
	end

	phase = 1
	lastPhase = 1
	wipe(phaseOrder)
	phaser = nil
	councilEncounter = councilStyleEncounters[encounterID] and true or false
	isThisCouncilEncounter = councilStyleEncounters[encounterID] and true or false
	ignorePhasesEncounter = ignorePhasesEncounters[encounterID] and true or false
	wipe(graphData)
	snapshot = nil -- lastPercent
	wipe(lastPercent) -- lastPercent
	wipe(previousPercent) -- lastPercent
	_initDB(graphData, dataDefaults)
	setmetatable(graphData.data, graphDataMetaTable)
	graphData.info = {
		["instanceID"] = EJ_GetInstanceForMap(C_Map.GetBestMapForUnit("player")), --EJ_GetCurrentInstance(),
		["encounterID"] = encounterID,
		["encounterName"] = encounterName,
		["difficultyID"] = difficultyID,
		["raidSize"] = raidSize,
		["councilEncounter"] = councilEncounter,
		["ignorePhasesEncounter"] = ignorePhasesEncounter
	}
	startTime = now
	timer = 0
	self:SetScript("OnUpdate", CombatTimer)

	--self:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

function f:ENCOUNTER_END(event, encounterID, encounterName, difficultyID, raidSize, endStatus)
	Debug("EE:", event, encounterID, encounterName, difficultyID, raidSize, endStatus)
	if DBM and phaser then
		Debug("> Phase: %d, Bosses left: %d / %d.", DBM.Mods[phaser].vb.phase or 1, DBM.Mods[phaser].vb.bossLeft or -1, DBM.Mods[phaser].numBoss or -1)
	else
		Debug(">>> No phaser!")
	end

	jammer = GetTime()
	self:SetScript("OnUpdate", nil)
	graphData.info = {
		["instanceID"] = graphData.info.instanceID == 0 and EJ_GetInstanceForMap(C_Map.GetBestMapForUnit("player")) or graphData.info.instanceID, --EJ_GetCurrentInstance()
		["encounterID"] = graphData.info.encounterID or encounterID,
		["encounterName"] = graphData.info.encounterName or encounterName,
		["difficultyID"] = graphData.info.difficultyID or difficultyID,
		["raidSize"] = graphData.info.raidSize or raidSize,
		["endStatus"] = endStatus,
		["timer"] = timer,
		["timestamp"] = date("!%Y.%m.%d - %H:%M:%S", GetServerTime()), --date("!%Y.%m.%d - %H:%M"),
		["playerName"] = (UnitFullName("player")),
		["councilEncounter"] = councilEncounter,
		["ignorePhasesEncounter"] = ignorePhasesEncounter
	}
	councilEncounter = false

	--if recordThis[difficultyID] then
		self:ProcessData(graphData)
	--end

	--self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

do -- GROUP_ROSTER_UPDATE
	local throttling

	local function DelayedUpdate()
		throttling = nil

		-- Update the size of the group
		-- Should save some time if we update only on GROUP_ROSTER_UPDATE to reduce the calls on CombatTimer snapshots
		numGroupMembers = GetNumGroupMembers() -- This is one off in party, but it shouldn't matter because we have checks for it later
	end

	local function ThrottleUpdate(self, event, ...)
		if not throttling then
			throttling = true
			C_Timer.After(0.5, DelayedUpdate)
		end
	end

	f.GROUP_ROSTER_UPDATE = ThrottleUpdate -- Throttle
end


--------------------------------------------------------------------------------
-- Slash Handler
--------------------------------------------------------------------------------
SLASH_FIGHTRECORDER1 = "/frec"

local SlashHandlers = {
	["show"] = function()
		Frame:Show()
	end,
	["hide"] = function()
		Frame:Hide()
	end,
	["reset"] = function()
		wipe(dataDB)
		wipe(bossDB)
		wipe(progressDB)
		wipe(graphData)
		_initDB(graphData, dataDefaults)
		f:selectReset(3)
		Frame:SetStatusText("Reseted DB.")
		Frame:Show()
	end,
	["list"] = function()
		for i = 1, 50 do
			local name, mode = GetDifficultyInfo(i)
			Debug("["..i.."] = "..((name) and "true" or "false")..", --", name, ", ", mode)
		end
	end,
	["instance"] = function()
		local uiMapID = C_Map.GetBestMapForUnit("player")
		if uiMapID then
			local instanceID = EJ_GetInstanceForMap(C_Map.GetBestMapForUnit("player"))
			Print("Instance ID: %d (%s) (%d)", instanceID, EJ_GetInstanceInfo(instanceID) or "n/a", uiMapID)
		else
			Print("Instance ID: %d (%s) (%d)", 0, EJ_GetInstanceInfo(0) or "n/a", uiMapID)
		end
	end,
	["boss"] = function()
		local GUID = UnitGUID("target")
		local bossID = "n/a"
		local bossName = UnitFullName("target") or "no target"
		if GUID then
			local _, _, _, _, _, npcID = strsplit("-", GUID)
			if npcID and tonumber(npcID) > 0 then
				bossID = npcID
			end
		end

		Print("[%s] = \"%s\",", bossID, bossName)
	end,
	["populate"] = function()
		-- Populate RaidData.lua

		local ignoredInstaces = {
			-- World Bosses
			[322] = true, -- MoP
			[557] = true, -- WoD
			[822] = true, -- Legion
			[1028] = true, -- BfA
			[1192] = true, -- SL

			-- Other
			[959] = true, -- Invasion Points (Legion)
		}
		local list = "\n"
		local order = "\n"

		local tiers = EJ_GetNumTiers()
		for i = 1, tiers do
			EJ_SelectTier(i)

			local index = 1
			local instanceID = EJ_GetInstanceByIndex(index, true)
			while instanceID do
				if ignoredInstaces[instanceID] or RaidEncounterIDs[instanceID] then
					--[[
					if ignoredInstaces[instanceID] then
						Debug("- Ignored %d", instanceID)
					elseif RaidEncounterIDs[instanceID] then
						Debug("- Already saved %d", instanceID)
					else
						Debug("- WTF? %d", instanceID)
					end
					]]
				else
					EJ_SelectInstance(instanceID)
					local instanceName = EJ_GetInstanceInfo()
					list = ("%s        -- %s\n        [%d] = {\n"):format(list, instanceName, instanceID)
					order = ("%s            [%d] = %d, -- %s\n\n            -- %s\n"):format(order, instanceID, (index - 1), instanceName, instanceName)

					local EJIndex = 1
					local bossName, _, bossID, _, _, _, encounterID = EJ_GetEncounterInfoByIndex(EJIndex)
					while bossName do
						if encounterID then
							list = ("%s            [%d] = \"%s\",\n"):format(list, encounterID, bossName)
							order = ("%s                [%d] = %d, -- %s\n"):format(order, encounterID, EJIndex, bossName)
						end

						EJIndex = EJIndex + 1
						bossName, _, bossID = EJ_GetEncounterInfoByIndex(EJIndex)

						if encounterID and not bossName then -- Remove last comma from the last boss of the instance
							--list = string.sub(list, 1, ( #list - 2 )) .. "\n" -- Works
							list = list:sub(1, -3) .. "\n" -- Shorter
						end
					end

					list = ("%s        },\n\n"):format(list)
					order = ("%s\n\n"):format(order)
				end

				index = index + 1
				instanceID = EJ_GetInstanceByIndex(index, true)
			end

		end

		Debug("\nList:\n" .. list .. "\nOrder:\n" .. order)
	end,
	["clear"] = function()
		local function shallowcopy(orig) -- http://lua-users.org/wiki/CopyTable
			local orig_type = type(orig)
			local copy
			if orig_type == 'table' then
				copy = {}
				for orig_key, orig_value in pairs(orig) do
					copy[orig_key] = orig_value
				end
			else -- number, string, boolean, etc
				copy = orig
			end
			return copy
		end

		-- Phase 1 - Removing data from the bossDB which was saved as "unknown what to do with" -data, but is now hardcoded into the RaidData.lua
		local rI, rE, rB = 0, 0, 0
		local tI, tE, tB = 0, 0, 0
		local instanceCounter, encounterCounter, bossCounter = 0, 0, 0
		for instanceID, instanceData in pairs(bossDB) do -- Iterate bossDB and remove already hardcoded data
			if instanceID ~= "name" then
				tI = tI + 1
				encounterCounter = 0

				for encounterID, encounterData in pairs(instanceData) do
					if RaidEncounterIDs[instanceID] and RaidEncounterIDs[instanceID][encounterID] then
						bossDB[instanceID][encounterID] = nil
						rE = rE + 1
					elseif encounterID ~= "name" and encounterID ~= "roster" then
						tE = tE + 1
						bossCounter = 0

						for bossID in pairs(encounterData) do
							if RaidBosses[bossID] or BossAdds[bossID] then
								bossDB[instanceID][encounterID][bossID] = nil
								rB = rB + 1
							elseif bossID ~= "name" then
								tB = tB + 1
								bossCounter = bossCounter + 1
							end
						end
						if bossCounter == 0 then
							bossDB[instanceID][encounterID] = nil
							rE = rE + 1
						else
							encounterCounter = encounterCounter + 1
						end
					end
				end
				if encounterCounter == 0 then
					bossDB[instanceID] = nil
					rI = rI + 1
					tI = tI - 1
				else
					instanceCounter = instanceCounter + 1
				end
			end
		end
		Print("1. bossDB (Unknown boss or add data):\n     Cleared %d bosses, %d encounters and %d instances.\n     Left %d bosses in %d encounters and %d instances.", rB, rE, rI, tB, tE, tI)

		-- Phase 2 -  Move Fixable data to the right place in dataDB and progressDB
		local bMove, bSkip, pMove, pSkip, rMove, rSkip = 0, 0, 0, 0, 0, 0
		for wrongId, rightData in pairs(instanceIDFixes) do
			if dataDB[wrongId] then
				for encounterID, rightId in pairs(rightData) do
					if dataDB[wrongId][encounterID] then
						-- Something to move
						Print("Trying to move %d %s (%d -> %d)", encounterID, RaidEncounterIDs[rightId][encounterID] or "n/a", wrongId, rightId) -- Debug

						-- Create table for bossData if needed
						dataDB[rightId] = dataDB[rightId] or {}

						-- Create table for progressData if needed
						progressDB[rightId] = progressDB[rightId] or {}

						-- Copy the data to the right place, but only if previous entry doesn't exist
						if not dataDB[rightId][encounterID] then
							Debug("Phase 2, dataDB Moving: %d -> %d (%d)", wrongId, rightId, encounterID)
							dataDB[rightId][encounterID] = shallowcopy(dataDB[wrongId][encounterID])
							bMove = bMove + 1
						else
							Debug("Phase 2, dataDB Skipping: %d >< %d (%d)", wrongId, rightId, encounterID)
							bSkip = bSkip + 1
						end
						if not progressDB[rightId][encounterID] then
							Debug("Phase 2, progressDB Moving: %d -> %d (%d)", wrongId, rightId, encounterID)
							progressDB[rightId][encounterID] = shallowcopy(progressDB[wrongId][encounterID])
							pMove = pMove + 1
						else
							Debug("Phase 2, progressDB Skipping: %d >< %d (%d)", wrongId, rightId, encounterID)
							pSkip = pSkip + 1
						end

						-- Check if we have to move roster as well
						if progressDB[wrongId]["roster"] then
							local wrongRoster = progressDB[wrongId]["roster"]
							local rightRoster = progressDB[rightId]["roster"] or {}

							for name, rosterInfo in pairs(wrongRoster) do
								-- No entry for Name in rightRoster
								if not rightRoster[name] then
									Debug("Phase 2, rosterInfo Moving: %s, %d -> %d", name, wrongId, rightId)
									rightRoster[name] = shallowcopy(rosterInfo)
									rMove = rMove + 1
								else
									--Debug("Phase 2, rosterInfo Skipping: %s, %d >< %d", name, wrongId, rightId)
									rSkip = rSkip + 1
								end
							end
						end
					else
						-- Nothing to move
					end
				end
			end
		end
		Print("2. dataDB&progressDB (Fix instanceIDs):\n     Moved %d encounters while skipping %d encounters in dataDB.\n     Moved %d encounters while skipping %d encounters in progressDB\n     Moved %d entries while skipping %d entries in rosterInfo", bMove, bSkip, pMove, pSkip, rMove, rSkip)

		-- Phase 3 - Iterate dataDB for invalid data
		local nullifier = 0
		local skipped, cleared = false, false
		for instanceID, instanceData in pairs(dataDB) do -- instanceID
			if (bMove == pMove and bMove > 0) and (bSkip == pSkip and bSkip == 0) then -- Remove unfixed data only if it was fixed
				if instanceIDFixes[instanceID] then -- Remove unfixed data
					dataDB[instanceID] = nil
					progressDB[instanceID] = nil
					cleared = true
				end
			elseif (bSkip > 0 or bMove > 0) then -- Mark 'skipped' only if really skipped something
				skipped = true
			end
			for _, encounterData in pairs(instanceData) do -- encounterID
				for _, difficultyData in pairs(encounterData) do -- difficultyID
					if difficultyData and difficultyData.data then
						for _, timeData in pairs(difficultyData.data) do -- Tick
							if timeData and timeData.health then
								for _, spawn in pairs(timeData.health) do -- npcID
									for spawnID, health in pairs(spawn) do
										if type(health) ~= "number" then
											spawn[spawnID] = nil
											nullifier = nullifier + 1
										end
									end
								end
							end
						end
					end
				end
			end
		end
		Print("3. dataDB (Graph data):\n     %d nils removed from dataDB.%s", nullifier, skipped and " Skipped UNFIXED data!" or (cleared and " Cleared unfixed data." or ""))

		-- Phase 4 - Clean progressDB for old entries that has their dataDB-data removed
		local pI, pE, pD = 0, 0, 0
		for instanceID, instanceData in pairs(progressDB) do
			if not dataDB[instanceID] then
				progressDB[instanceID] = nil
				pI = pI + 1
			else
				for encounterID, encounterData in pairs(instanceData) do
					if encounterID ~= "roster" then -- progressDB[info.instanceID]["roster"]
						if not dataDB[instanceID][encounterID] then
							instanceData[encounterID] = nil
							pE = pE + 1
						else
							for difficultyID, difficultyData in pairs(encounterData) do
								if not dataDB[instanceID][encounterID][difficultyID] then
									encounterData[difficultyID] = nil
									pD = pD + 1
								end
							end
						end
					else
						Debug("> Skipping Roster for %d (%s)", instanceID, EJ_GetInstanceInfo(instanceID) or "n/a")
					end
				end
			end
		end
		Print("4. progressDB (ProgressGraph data):\n     %d difficulties, %d encounters and %d instances removed from progressDB as obsolete.", pD, pE, pI)

		-- Final check to get rid of empty tables in DBs
		-- Disableing this because it caused problems with bosses that hide for periods of time with their bossframes hiding also (like 'The Prophet Skitra') and causing cutting of the tail of the graph.
		-- I think I have managed to work around the gaps in the plotting, so re-enabling this.
		_cleanDB(dataDB)
		_cleanDB(bossDB)
		_cleanDB(progressDB)
		if list and _UpdateTree then -- Update tree just in case
			list:SetTree(_UpdateTree(dataDB))
		end
		Print("-- Done!")
	end,
	["test"] = function(params)
		if not params or params == "1" then
			f:selectDrawing(1, dataDB[875][2032][14], dataDB[875][2032][15]) -- Tomb of Sargeras / Goroth / Normal - Heroic
		elseif params == "2" then
			f:selectDrawing(1, dataDB[875][2037][14]) -- Tomb of Sargeras / Mistress Sassz'ine / Normal
			f:selectDrawing(2, progressDB[875][2037][15]) -- Tomb of Sargeras / Mistress Sassz'ine / Heroic
		elseif params == "3" then
			f:selectDrawing(1, dataDB[875][2054][14]) -- Tomb of Sargeras / The Desolate Host / Normal
		elseif params == "4" then
			f:selectDrawing(1, dataDB[768][1841][14]) -- The Emerald Nightmare / Ursoc / Normal
		else
			Print("Params:", tostring(params))
		end

	end,
	["debug"] = function(params)
		Print("Params:", tostring(params))
		local newParams = { strsplit(" ", params) }
		Print("newParams:", tostringall(newParams))
	end,
}

SlashCmdList["FIGHTRECORDER"] = function(text)
	local command, params = strsplit(" ", text, 2)
	if SlashHandlers[command] then
		SlashHandlers[command](params)
	else
		--Frame:Show()
		if Frame:IsShown() then
			Frame:Hide()
		else
			Frame:Show()
		end
	end
end


--------------------------------------------------------------------------------
-- #EOF
--------------------------------------------------------------------------------