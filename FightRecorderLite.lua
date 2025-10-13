--[[----------------------------------------------------------------------------
	FightRecorder Lite

	2023-2025
	Sanex @ EU-Arathor / ahak @ Curseforge

	Records npcId's from raid encounters for FightRecorder to use.
----------------------------------------------------------------------------]]--
local ADDON_NAME, ns = ... -- Addon name and private namespace

local ignoredInstaces = {
	-- World Bosses
	[322] = true, -- MoP
	[557] = true, -- WoD
	[822] = true, -- Legion
	[1028] = true, -- BfA
	[1192] = true, -- SL
	[1205] = true, -- DF
	[1278] = true, -- TWW

	-- Other
	[959] = true, -- Invasion Points (Legion)
}
local raidDifficulties = {
	DifficultyUtil.ID.Raid10Normal, -- 3
	DifficultyUtil.ID.Raid25Normal, -- 4
	DifficultyUtil.ID.Raid10Heroic, -- 5
	DifficultyUtil.ID.Raid25Heroic, -- 6
	DifficultyUtil.ID.RaidLFR, -- 7
	DifficultyUtil.ID.Raid40, -- 9
	DifficultyUtil.ID.PrimaryRaidNormal, -- 14
	DifficultyUtil.ID.PrimaryRaidHeroic, -- 15
	DifficultyUtil.ID.PrimaryRaidMythic, -- 16
	DifficultyUtil.ID.PrimaryRaidLFR, -- 17
	DifficultyUtil.ID.RaidTimewalker, -- 33
	DifficultyUtil.ID.RaidStory -- 220
}


--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------
-- GLOBALS: FightRecorderBossData, SLASH_FIGHTRECORDERLITE1

-- GLOBALS: _G, C_AddOns, C_Map, ChatFrame3, ChatFrame4, CreateFrame
-- GLOBALS: DEBUG_CHAT_FRAME, DEFAULT_CHAT_FRAME, DifficultyUtil
-- GLOBALS: EJ_GetDifficulty, EJ_GetEncounterInfoByIndex, EJ_GetInstanceByIndex
-- GLOBALS: EJ_GetInstanceForMap, EJ_GetInstanceInfo, EJ_GetNumTiers
-- GLOBALS: EJ_IsValidInstanceDifficulty, EJ_SelectInstance, EJ_SelectTier
-- GLOBALS: EJ_SetDifficulty, format, GetBuildInfo, IsEncounterInProgress
-- GLOBALS: IsLoggedIn, math, next, OKAY, pairs, select, SlashCmdList
-- GLOBALS: StaticPopup_Show, StaticPopupDialogs, string, strjoin, tostring
-- GLOBALS: tostringall, type, UnitFullName, wipe, WrapTextInColorCode


--------------------------------------------------------------------------------
-- Local upvalues
--------------------------------------------------------------------------------
local _G = _G
local strsplit = _G.strsplit
local tonumber = _G.tonumber
local UnitGUID = _G.UnitGUID
local UnitHealth = _G.UnitHealth
local UnitName = _G.UnitName


--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local bossDB
local encounterData, recordedUnits = {}, {}
local recUnits = {
	"boss1",
	"boss2",
	"boss3",
	"boss4",
	"boss5"
}
-- "Import" stuff from RaidData.lua so I don't have to keep typing 'ns' all the time
local expansionTierNames = ns.expansionTierNames
local recordThis = ns.recordThis
local instanceIDFixes = ns.instanceIDFixes
local RaidEncounterIDs = ns.RaidEncounterIDs
local BossAdds = ns.BossAdds
local RaidBosses = ns.RaidBosses


--------------------------------------------------------------------------------
-- Debuging & Output
--------------------------------------------------------------------------------
local DEBUGMODE = true
local function Debug(text, ...)
	if not DEBUGMODE then return end

	if text then
		if text:match("%%[dfqsx%d%.]") then
			(DEBUG_CHAT_FRAME or (ChatFrame3:IsShown() and ChatFrame3 or ChatFrame4)):AddMessage("|cffff9999"..ADDON_NAME..":|r " .. format(text, ...))
		else
			(DEBUG_CHAT_FRAME or (ChatFrame3:IsShown() and ChatFrame3 or ChatFrame4)):AddMessage("|cffff9999"..ADDON_NAME..":|r " .. strjoin(" ", text, tostringall(...)))
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
-- Table to String, modified from https://gist.github.com/justnom/9816256
--------------------------------------------------------------------------------
local indentation = 4
local function _tableToString(tbl, depth) -- Convert a lua table into a lua syntactically correct string
	local d = depth or 1
	local result = "{\n"
	for k, v in pairs(tbl) do
		-- Check the key type (ignore any numerical keys - assume its an array)
		if type(k) == "string" then
			result = result .. string.rep(" ", d * indentation) .. "[\"" .. k .. "\"] = "
		else
			result = result .. string.rep(" ", d * indentation) .. "[" .. k .. "] = "
		end

		-- Check the value type
		if type(v) == "table" then
			result = result .. _tableToString(v, d + 1)
		elseif type(v) == "boolean" then
			result = result .. tostring(v) .. ""
		else
			result = result .. "\"" .. v .. "\""
		end
		result = result .. ",\n"
	end
	-- Remove leading commas from the result
	if result ~= "{" then
		result = result:sub(1, result:len()-1)
	end
	return result .. "\n" .. string.rep(" ", (d - 1) * indentation) .. "}"
end


--------------------------------------------------------------------------------
-- Table Length, modified from https://stackoverflow.com/a/2705804
--------------------------------------------------------------------------------
local function _tableLength(T)
	local count = 0
	for _, subtableTest in pairs(T) do
		if type(subtableTest) == "table" then
			count = count + _tableLength(subtableTest)
		else
			count = count + 1
		end
	end
	return count
end


--------------------------------------------------------------------------------
-- Event Frame
--------------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)


--------------------------------------------------------------------------------
-- Snapshotting
--------------------------------------------------------------------------------
local function recordBossFrameNpcIds()
	for i = 1, #recUnits do
		if UnitHealth(recUnits[i]) > 0 then
			local guid = UnitGUID(recUnits[i])

			local unitType, _, _, _, _, npcId = strsplit("-", guid)
			npcId = tonumber(npcId) or npcId or unitType

			if npcId and not recordedUnits[npcId] then -- Fight the -1.#IND HP ghosts (Eonar)
				recordedUnits[npcId] = UnitName(recUnits[i])
			end
		end
	end
end


--------------------------------------------------------------------------------
-- Parse data
--------------------------------------------------------------------------------
function f:ProcessData() -- Process data after ENCOUNTER_END
	--[[
		bossDB = {
			[1180] = {
				["name"] = "Ny'alotha, the Waking City",
				[2328] = {
					["name"] = "Dark Inquisitor Xanesh",
					[156575] = "Dark Inquisitor Xanesh",
				},
				[2327] = {
					["name"] = "Maut",
					[156650] = "Dark Manifestation",
				},
				[2334] = {
					["name"] = "Prophet Skitra",
					[157238] = "Prophet Skitra",
				},
			},
		}
	]]--
	local difficultyId = encounterData.difficultyId
	local instanceId = encounterData.instanceId
	local encounterId = encounterData.encounterId
	local encounterName = encounterData.encounterName

	if (not difficultyId) or (not recordThis[difficultyId]) then return end

	-- Check if the instanceId needs fixing
	if instanceIDFixes[instanceId] and instanceIDFixes[instanceId][encounterId] then
		Debug("!!! Fixing instanceId:", instanceId, "->", instanceIDFixes[instanceId][encounterId])
		instanceId = instanceIDFixes[instanceId][encounterId]
	end

	for npcId, npcName in pairs(recordedUnits) do -- List all new npcId's
		if (not RaidBosses[npcId]) and (not BossAdds[npcId]) then -- Not known Boss or Boss minion

			if not bossDB[instanceId] then -- New instanceId
				bossDB[instanceId] = { name = (EJ_GetInstanceInfo(instanceId)) }
			end

			if not bossDB[instanceId][encounterId] then -- New encounterId
				bossDB[instanceId][encounterId] = { name = encounterName }
			end

			if (not bossDB[instanceId][encounterId][npcId]) or (bossDB[instanceId][encounterId][npcId] == "Unknown" and tostring(npcName) ~= "Unknown") then -- new npcId
				bossDB[instanceId][encounterId][npcId] = tostring(npcName)
				Debug("> New NPC: %s (%d)", tostring(npcName), tonumber(npcId))
			end
		end
	end
end


--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------
function f:ADDON_LOADED(event, addon)
	if addon ~= ADDON_NAME then return end
	self:UnregisterEvent("ADDON_LOADED")

	if C_AddOns.IsAddOnLoaded("FightRecorder") then
		Debug("STOPPED LOADING", ADDON_NAME, "(FightRecorder already loaded)")
		return
	end

	FightRecorderBossData = _initDB(FightRecorderBossData)
	bossDB = FightRecorderBossData

	if IsLoggedIn() then
		self:PLAYER_LOGIN()
	else
		self:RegisterEvent("PLAYER_LOGIN")
	end

	Debug(event, addon)
	self.ADDON_LOADED = nil
end

function f:PLAYER_LOGIN(event)
	self:UnregisterEvent("PLAYER_LOGIN")

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ENCOUNTER_START")
	self:RegisterEvent("ENCOUNTER_END")
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")

	Debug(event)
	self.PLAYER_LOGIN = nil
end

local triggerCount = 0
function f:PLAYER_ENTERING_WORLD(event)
	if IsEncounterInProgress() then
		Debug("Entered while encounter already in progress.")

		encounterData.instanceId = EJ_GetInstanceForMap(C_Map.GetBestMapForUnit("player"))

		triggerCount = 1
		recordBossFrameNpcIds()
	end
end

function f:ENCOUNTER_START(event, encounterId, encounterName, difficultyId, raidSize)
	Debug(event, encounterId, encounterName, difficultyId, raidSize)

	wipe(recordedUnits)
	wipe(encounterData)
	encounterData.instanceId = EJ_GetInstanceForMap(C_Map.GetBestMapForUnit("player"))
	encounterData.encounterId = encounterId
	encounterData.encounterName = encounterName
	encounterData.difficultyId = difficultyId
	encounterData.raidSize = raidSize

	triggerCount = 1
	recordBossFrameNpcIds()
end

function f:ENCOUNTER_END(event, encounterId, encounterName, difficultyId, raidSize, endStatus)
	Debug(event, encounterId, encounterName, difficultyId, raidSize, endStatus, ">", triggerCount, "<")

	encounterData.instanceId = encounterData.instanceId or EJ_GetInstanceForMap(C_Map.GetBestMapForUnit("player"))
	encounterData.encounterId = encounterData.encounterId or encounterId
	encounterData.encounterName = encounterData.encounterName or encounterName
	encounterData.difficultyId = encounterData.difficultyId or difficultyId
	encounterData.raidSize = encounterData.raidSize or raidSize
	encounterData.endStatus = encounterData.endStatus or endStatus

	self:ProcessData()
end

function f:INSTANCE_ENCOUNTER_ENGAGE_UNIT(event)
	Debug(event)

	triggerCount = triggerCount + 1
	recordBossFrameNpcIds()
end


--------------------------------------------------------------------------------
-- Slash Handler
--------------------------------------------------------------------------------
SLASH_FIGHTRECORDERLITE1 = "/frec"

StaticPopupDialogs["FRECLITE_DEBUG"] = {
	text = "Detected expansion version: " .. WrapTextInColorCode(math.floor(select(4, GetBuildInfo()) / 10000), "ffffcc00") .. "\n"
		.. WrapTextInColorCode("Encounter Journal", "ffcccccc") .. " unknown entries: " .. WrapTextInColorCode("%d", "ffffcc00") .. "\n"
		.. WrapTextInColorCode("bossDB", "ffcccccc") .. " unknown entries: " .. WrapTextInColorCode("%d", "ffffcc00") .. "\n\n"
		.. "Copy&paste the debug text from the editbox below, even if the editbox looks empty:\n\n"
		.. "(Use " .. WrapTextInColorCode("Ctrl+A", "ffffcc00") .. " to select text, " .. WrapTextInColorCode("Ctrl+C", "ffffcc00") .. " to copy text)",
	SubText = "-- They changed this from editBox to EditBox, but this also causes now taints?",
	button1 = OKAY,
	showAlert = true,
	hasEditBox = true,
	editBoxWidth = 260, --350,
	-- They changed this from editBox to EditBox, but this also causes now taints?
	OnShow = function (self, data)
		--self.EditBox:SetText("Something went wrong!") -- This will be overwritten if everything goes as expected
		self:GetEditBox():SetText("Something went wrong!")
	end,
	EditBoxOnTextChanged = function (this, data) -- careful! 'this' here points to the editbox, not the dialog
		if this:GetText() ~= data then
			this:SetText(data)
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true
}

local SlashHandlers = {
	["reset"] = function()
		wipe(recordedUnits)
		wipe(encounterData)
		wipe(bossDB)
	end,
	["instance"] = function()
		local uiMapId = C_Map.GetBestMapForUnit("player")
		if uiMapId then
			local instanceId = EJ_GetInstanceForMap(uiMapId)
			Print("instanceId: %d (%s) (%d)", instanceId, EJ_GetInstanceInfo(instanceId) or "n/a", uiMapId)
		else
			Print("instanceId: %d (%s) (%d)", 0, EJ_GetInstanceInfo(0) or "n/a", uiMapId)
		end
	end,
	["boss"] = function()
		local GUID = UnitGUID("target")
		local npcId = "n/a"
		local bossName = UnitFullName("target") or "no target"
		if GUID then
			local _, _, _, _, _, npcIdFromGUID = strsplit("-", GUID)
			if npcIdFromGUID and tonumber(npcIdFromGUID) > 0 then
				npcId = npcIdFromGUID
			end
		end

		Print("[%s] = \"%s\",", npcId, bossName)
	end,
}

SlashCmdList["FIGHTRECORDERLITE"] = function(text)
	local command, params = strsplit(" ", text, 2)
	if SlashHandlers[command] then
		SlashHandlers[command](params)
	else
		-- Populate RaidData.lua
		local testDB = { -- Debug
			[1180] = {
				["name"] = "Ny'alotha, the Waking City",
				[2328] = {
					["name"] = "Dark Inquisitor Xanesh",
					[156575] = "Dark Inquisitor Xanesh",
				},
				[2327] = {
					["name"] = "Maut",
					[156650] = "Dark Manifestation",
				},
				[2334] = {
					["name"] = "Prophet Skitra",
					[157238] = "Prophet Skitra",
				},
			},
		}

		Print("Exporting collected data:")

		-- Phase 1 - Removing data from the bossDB which was saved as "unknown what to do with" -data, but is now hardcoded into the RaidData.lua
		local rI, rE, rB = 0, 0, 0
		local tI, tE, tB = 0, 0, 0
		local instanceCounter, encounterCounter, bossCounter = 0, 0, 0
		for instanceId, instanceData in pairs(bossDB) do -- Iterate bossDB and remove already hardcoded data
			if instanceId ~= "name" then
				tI = tI + 1
				encounterCounter = 0

				for encounterId, encounterData in pairs(instanceData) do
					if encounterId ~= "name" then
						tE = tE + 1
						bossCounter = 0

						for npcId in pairs(encounterData) do
							if RaidBosses[npcId] or BossAdds[npcId] then
								bossDB[instanceId][encounterId][npcId] = nil
								rB = rB + 1
							elseif npcId ~= "name" then
								tB = tB + 1
								bossCounter = bossCounter + 1
							end
						end
						if bossCounter == 0 then
							bossDB[instanceId][encounterId] = nil
							rE = rE + 1
							tE = tE - 1
						else
							encounterCounter = encounterCounter + 1
						end
					end
				end
				if encounterCounter == 0 then
					bossDB[instanceId] = nil
					rI = rI + 1
					tI = tI - 1
				else
					instanceCounter = instanceCounter + 1
				end
			end
		end
		if rI > 0 or rE > 0 or rB > 0 then
			Print(
				"- Cleared %d bosses, %d encounters and %d instances from bossDB.\n" ..
				"- Left %d bosses in %d encounters and %d instances to bossDB.",
				rB, rE, rI,
				tB, tE, tI
			)
		end

		_cleanDB(bossDB)


		-- Phase 2 - Check EJ for new instances and encounters and export them and bossDB
		local encounterList, instanceExpansionOrder, instanceOrder, bossOrder = "", "", "", ""
		local numInstances, newInstances, newEntries = 0, 0, 0

		local tiers = EJ_GetNumTiers()
		for i = 1, tiers do
			EJ_SelectTier(i)

			local tierAdded = false
			local index = 1
			local orderIndex = 1
			local instanceId = EJ_GetInstanceByIndex(index, true)

			while instanceId do
				numInstances = numInstances + 1

				if (not ignoredInstaces[instanceId]) and (not RaidEncounterIDs[instanceId]) then
					newInstances = newInstances + 1
					newEntries = newEntries + 1
					ignoredInstaces[instanceId] = true -- in DF both tier 10 and 11 are returning same instances, this prevents double data on export

					if not tierAdded then
						tierAdded = true
						-- Format --
						encounterList = ("%s    -- %s\n"):format(encounterList, expansionTierNames[i] or i)
						instanceExpansionOrder = ("%s\n        -- %s\n"):format(instanceExpansionOrder, expansionTierNames[i] or i)
						instanceOrder = ("%s\n        -- %s\n"):format(instanceOrder, expansionTierNames[i] or i)
						bossOrder = ("%s        -- %s\n"):format(bossOrder, expansionTierNames[i] or i)
						------------
					end

					EJ_SelectInstance(instanceId)
					-- Set Maximum difficulty to get also Heroic only bosses
					local difficultyId = EJ_GetDifficulty()
					for j = 1, #raidDifficulties do
						local isValid = EJ_IsValidInstanceDifficulty(raidDifficulties[j])
						if isValid then
							--Debug("isValid", j, raidDifficulties[j])
							difficultyId = raidDifficulties[j]
							break
						end
					end
					EJ_SetDifficulty(difficultyId)

					local instanceName = EJ_GetInstanceInfo()
					-- Format --
					encounterList = ("%s        -- %s\n        [%d] = {\n"):format(encounterList, instanceName, instanceId)
					instanceExpansionOrder = ("%s            [%d] = %d, -- %s\n"):format(instanceExpansionOrder, instanceId, i, instanceName)
					instanceOrder = ("%s            [%d] = %d, -- %s\n"):format(instanceOrder, instanceId, orderIndex, instanceName)
					bossOrder = ("%s            -- %s\n"):format(bossOrder, instanceName)
					------------

					local EJIndex = 1
					local bossName, _, bossId, _, _, _, encounterId = EJ_GetEncounterInfoByIndex(EJIndex)

					while bossName do
						if encounterId then
							newEntries = newEntries + 1
							-- Format --
							encounterList = ("%s            [%d] = \"%s\",\n"):format(encounterList, encounterId, bossName)
							bossOrder = ("%s                [%d] = %d, -- %s\n"):format(bossOrder, encounterId, EJIndex, bossName)
							------------
						end

						EJIndex = EJIndex + 1
						bossName, _, bossId, _, _, _, encounterId = EJ_GetEncounterInfoByIndex(EJIndex)

						if encounterId and not bossName then -- Remove last comma from the last boss of the instance
							--encounterList = string.sub(encounterList, 1, ( #encounterList - 2 )) .. "\n" -- Works
							encounterList = encounterList:sub(1, -3) .. "\n" -- Shorter
						end
					end

					-- Format --
					encounterList = ("%s        },\n\n"):format(encounterList)
					bossOrder = ("%s\n"):format(bossOrder)
					------------

					orderIndex = orderIndex + 1
				else
					--[[
					if ignoredInstaces[instanceId] then
						Debug("- Ignored %d", instanceId)
					elseif RaidEncounterIDs[instanceId] then
						Debug("- Already saved %d", instanceId)
					else
						Debug("- WTF? %d", instanceId)
					end
					]]
					if not ignoredInstaces[instanceId] then -- Just added or already in RaidData.lua, increase the orderIndex
						orderIndex = orderIndex + 1
					end
				end

				index = index + 1
				instanceId = EJ_GetInstanceByIndex(index, true)
			end

		end

		local line = "No new instances found!"
		if newInstances > 0 then
			line = "RaidEncounterIDs:\n" .. encounterList .. "\norderTable:\n- instanceExpansion:" .. instanceExpansionOrder .. "\n- r:" .. instanceOrder .. "\n- e:\n" .. bossOrder
 			Print("- Found %d new instances from EJ.", newInstances)
		end
		line = line .. "\n\n"

		local dbCount = _tableLength(bossDB) -- bossDB / testDB
		if dbCount > 0 then
			line = line .. "bossDB = " .. _tableToString(bossDB) -- bossDB / testDB
		end
		line = string.trim(line)

		if newInstances > 0 or dbCount > 0 then
			local buildVersion, buildNumber, buildDate, interfaceVersion, localizedVersion, buildInfo, currentVersion = GetBuildInfo()
			line = format.string("Game: %s (%d / %s)\n", buildVersion, interfaceVersion, (currentVersion or "n/a")) .. line
		end

		--Debug("- Populate -> EJ: %d / %d, bossDB: %d", newEntries, newInstances, dbCount)
		local dialog = StaticPopup_Show("FRECLITE_DEBUG", newEntries, dbCount, line) -- Send to dialog for easy copy&paste for end user
		if dialog then
 			--dialog.data = line
 		end
	end
end


--------------------------------------------------------------------------------
-- #EOF
--------------------------------------------------------------------------------