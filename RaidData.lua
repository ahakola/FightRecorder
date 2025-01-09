--[[----------------------------------------------------------------------------
	RaidData IDs for FightRecorder

	Should containt every raid encounter and most of the npcId's of the bosses
	and adds. Misses some of the Mythic difficulty npcId's because I don't have
	access to all the fights when they are relevant and it is hard to catch
	them all alone later.

	2014-2025
	Sanex @ EU-Arathor / ahak @ Curseforge
----------------------------------------------------------------------------]]--
local ADDON_NAME, ns = ... -- Addon name and private namespace

--GLOBALS: DifficultyUtil, pairs

for _, v in pairs({ "RaidEncounterIDs", "BossAdds", "RaidBosses" }) do -- Create tables in private namespace, btw. this is a BAD way of doing this, but I was lazy
	ns[v] = ns[v] or {}
end


--[[----------------------------------------------------------------------------
	Expansion Pack short names

	[expansionTier] = string
----------------------------------------------------------------------------]]--
local expansionTierNames = {
	"CLASSIC",	-- 1
	"TBC",		-- 2
	"WRATH",	-- 3
	"CATA",		-- 4
	"MOP",		-- 5
	"WOD",		-- 6
	"LEGION",	-- 7
	"BFA",		-- 8
	"SL",		-- 9
	"DF",		-- 10
	"TWW",		-- 11
}
ns.expansionTierNames = expansionTierNames


--[[----------------------------------------------------------------------------
	difficultyIDs to record

	[difficultyID] = boolean
	Set boolean true to record difficultyID, false to skip recording.
	Use '/frec list' ingame to generate this list.
----------------------------------------------------------------------------]]--
local recordThis = {
	-- https://www.townlong-yak.com/framexml/10.2.0/DifficultyUtil.lua
	-- https://www.townlong-yak.com/framexml/live/Blizzard_FrameXMLUtil/DifficultyUtil.lua
	[DifficultyUtil.ID.DungeonNormal] = false,
	[DifficultyUtil.ID.DungeonHeroic] = false,
	[DifficultyUtil.ID.Raid10Normal] = true,
	[DifficultyUtil.ID.Raid25Normal] = true,
	[DifficultyUtil.ID.Raid10Heroic] = true,
	[DifficultyUtil.ID.Raid25Heroic] = true,
	[DifficultyUtil.ID.RaidLFR] = (ADDON_NAME == "FightRecorderLite") and true or false, -- Let FightRecorderLite record npcIds also on LFR
	[DifficultyUtil.ID.DungeonChallenge] = false,
	[DifficultyUtil.ID.Raid40] = true,
	[DifficultyUtil.ID.PrimaryRaidNormal] = true,
	[DifficultyUtil.ID.PrimaryRaidHeroic] = true,
	[DifficultyUtil.ID.PrimaryRaidMythic] = true,
	[DifficultyUtil.ID.PrimaryRaidLFR] = (ADDON_NAME == "FightRecorderLite") and true or false, -- Let FightRecorderLite record npcIds also on LFR
	[DifficultyUtil.ID.DungeonMythic] = false,
	[DifficultyUtil.ID.DungeonTimewalker] = false,
	[DifficultyUtil.ID.RaidTimewalker] = true,
	[DifficultyUtil.ID.RaidStory] = true,
}
ns.recordThis = recordThis


--[[
	Encounter IDs
	-- The Obsidian Sanctum
	[1091] = "Shadron",
	[1092] = "Tenebron",
	[1093] = "Vesperon",

	-- Ulduar
	[1164] = "Elder Brightleaf",
	[1165] = "Elder Ironbranch",
	[1166] = "Elder Stonebark",

	-- The Ruby Sanctum
	[1147] = "Baltharus the Warborn",
	[1148] = "General Zarithrian",
	[1149] = "Saviana Ragefire",

	-- MoP World bosses
	[1564] = "Sha of Anger",
	[1563] = "Galleon",
	[1571] = "Nalak",
	[1587] = "Oondasta",

	-- WoD World bosses
	[1755] = "Rukhmar, Sun-God of the Arakkoa",
	[1770] = "Tarlna the Ageless",
	[1801] = "Supreme Lord Kazzak",

	-- Legion World bosses
	[1879] = "The Soultakers",
	[1880] = "Nithogg",
	[1888] = "Shar'thos",
	[1917] = "Humongris",
	[1949] = "Drugon the Frostblood",
	[1950] = "Na'zak the Fiend",
	[1951] = "Flotsam",
	[1952] = "Calamir",
	[1953] = "Levantus",
]]--


--[[----------------------------------------------------------------------------
	Fixing incorrect instaceIDs. In old content (Classic and TBC) sometimes
	encounters are marked under wrong instanceID when moving from one area to
	another (for example AQ40 going under ground after first boss or Nigthbane
	in the balcony of Karazhan) and this table should provide the right
	instanceID when saving data to the DBs.

	[wrong instanceID] (list containing encounters in this wrong [instanceID])
		[encounterID] = right instanceID
		List of encounterIDs with their right instanceIDs.
		You find these in the bossDB if the encounters go under different
		instanceIDs when you know they are inside the same raid.
----------------------------------------------------------------------------]]--
local instanceIDFixes = {
	[0] = { -- nil
		-- Karazhan (The Broken Stair)
			[662] = 745, -- "Nightbane"

		-- Ulduar (The Mind's Eye)
			[1143] = 759, -- "Yogg-Saron"

		-- Battle of Dazar'alor (Battle of Dazar'alor)
			[2280] = 1176, -- "Stormwall Blockade" P1

		-- Ny'alotha, the Waking City (Vision of Destiny)
			[2329] = 1180, -- "Wrathion" (uiMapID 1580)
	},
	[227] = { -- Blackfathom Deeps ???
		-- Temple of Ahn'Qiraj (The Hive Undergrounds/Vault of C'Thun)
			[710] = 744, -- "Silithid Royalty"
			[711] = 744, -- "Battleguard Sartura"
			[712] = 744, -- "Fankriss the Unyielding"
			[713] = 744, -- "Viscidus"
			[714] = 744, -- "Princess Huhuran"
			[715] = 744, -- "Twin Emperors"
			[716] = 744, -- "Ouro"
			[717] = 744 -- "C'thun"
	}
}
ns.instanceIDFixes = instanceIDFixes


--[[----------------------------------------------------------------------------
	These ecnounters are 'council style' -encounters where you fight multiple
	bosses at the same time and you can choose the kill order yourself. In these
	fights the actual phases are replaced by number of bosses remaining.

	In some cases these might not be an actually fight multiple bosses, but you
	kill the same boss again and again between different phases. DBM handles
	(at least some of) these fights as 'coucil style' and counts how many times
	you have left to "kill" the boss before the actual final kill.

	!!! NOTICE !!!
	I have only tested the the BfA encounters, for them actualy working I'm just
	guessing these others works as well...

	[encounterID] = "Encounter Name"
	List of encounterIDs with their matching encounter names.
----------------------------------------------------------------------------]]--
local councilStyleEncounters = {
	-- MoP
		-- Terrace of Endless Spring
		[1409] = "Protectors of the Endless",

		-- Siege of Orgrimmar
		[1593] = "Paragons of the Klaxxi",

	-- BfA
		-- Battle of Dazar'alor
		[2268] = "Conclave of the Chosen",

		-- Ny'alotha, the Waking City
		[2345] = "Il'gynoth, Corruption Reborn",
}
ns.councilStyleEncounters = councilStyleEncounters


--[[----------------------------------------------------------------------------
	These ecnounters are alternating between different phases (like ground-phase
	and air-phase) until boss dies or you reach the last phase. Because
	sometimes these phases gets numbers (1, 2, ...) and you might get lower wipe
	than previous best, but the phase number is smaller, it wouldn't be recorded
	as a new record. With encounterIDs in this table we can ignore the phases
	and focus solely on the boss' HP.

	!!! NOTICE !!!
	I have only tested the the Ny'alotha encounters, for them actualy working
	I'm just guessing these others works as well...

	[encounterID] = "Encounter Name"
	List of encounterIDs with their matching encounter names.
----------------------------------------------------------------------------]]--
local ignorePhasesEncounters = {
	-- BfA
		-- Ny'alotha, the Waking City
			[2329] = "Wrathion, the Black Emperor",
			[2336] = "Vexiona",
}
ns.ignorePhasesEncounters = ignorePhasesEncounters


--[[----------------------------------------------------------------------------
	In some ecnounters players might get renamed and you might want to ignore
	those names in the guild check.

	["Name"] = true
	List of names to be ignored in guild check.
----------------------------------------------------------------------------]]--
local ignoredNames = {
	-- BfA
		-- Battle of Dazar'alor
		["Akunda the Wiped"] = true, -- Conclave of the Chosen
}
ns.ignoredNames = ignoredNames


--[[----------------------------------------------------------------------------
	These ecnounters we know the creatureIDs of the bosses and we can include
	RaidBosses instead of excluding BossAdds or guessing what to do.

	[instanceID] (list containing encounters of instance [instanceID])
		[encounterID] = "Encounter Name"
		List of encounterIDs with their matching encounter names.
----------------------------------------------------------------------------]]--
local RaidEncounterIDs = {
	Classic = {
		-- Molten Core
		[741] = {
			[663] = "Lucifron",
			[664] = "Magmadar",
			[665] = "Gehennas",
			[666] = "Garr",
			[667] = "Shazzrah",
			[668] = "Baron Geddon",
			[669] = "Sulfuron Harbinger",
			[670] = "Golemagg the Incinerator",
			[671] = "Majordomo Executus",
			[672] = "Ragnaros"
		},

		-- Blackwing Lair
		[742] = {
			[610] = "Razorgore the Untamed",
			[611] = "Vaelastrasz the Corrupt",
			[612] = "Broodlord Lashlayer",
			[613] = "Firemaw",
			[614] = "Ebonroc",
			[615] = "Flamegor",
			[616] = "Chromaggus",
			[617] = "Nefarian"
		},

		-- Ruins of Ahn'Qiraj
		[743] = {
			[718] = "Kurinnaxx",
			[719] = "General Rajaxx",
			[720] = "Moam",
			[721] = "Buru the Gorger",
			[722] = "Ayamiss the Hunter",
			[723] = "Ossirian the Unscarred"
		},

		-- Temple of Ahn'Qiraj
		[744] = {
			[709] = "The Prophet Skeram",
			-- These undeground bosses are in "Blackfathom Deeps" (227) instead of AQ40 (744) ???
			[710] = "Silithid Royalty",
			[711] = "Battleguard Sartura",
			[712] = "Fankriss the Unyielding",
			[713] = "Viscidus",
			[714] = "Princess Huhuran",
			[715] = "Twin Emperors",
			[716] = "Ouro",
			-- C'thun has proper instanceID (unless you are inside the boss, there you have 227)
			[717] = "C'thun"
		},

		-- Blackrock Depths (WoW 20th Anniversary Update)
		[1301] = {
			[3042] = "Lord Roccor",
			[3044] = "Bael'Gar",
			[3043] = "Lord Incendius",
			[3046] = "Golem Lord Argelmach",
			[3048] = "The Seven",
			[3045] = "General Angerforge",
			[3047] = "Ambassador Flamelash",
			[3049] = "Emperor Dagran Thaurissan",
		},
	},
	TBC = {
		-- Karazhan
		[745] = {
			-- No ID: Servant's Quarters (Rokad the Ravager, Shadikith the Glider, Hyakiss the Lurker)
			[652] = "Attumen the Huntsman",
			[653] = "Moroes",
			[654] = "Maiden of Virtue",
			[655] = "Opera Hall",
			[656] = "The Curator",
			[657] = "Terestian Illhoof",
			[658] = "Shade of Aran",
			[659] = "Netherspite",
			[660] = "Chess Event",
			[661] = "Prince Malchezaar",
			[662] = "Nightbane" -- Subzone "The Broken Stair" returns 0 as instanceID?
		},

		-- Gruul's Lair
		[746] = {
			[649] = "High King Maulgar",
			[650] = "Gruul the Dragonkiller"
		},

		-- Magtheridon's Lair
		[747] = {
			[651] = "Magtheridon"
		},

		-- Serpentshrine Cavern
		[748] = {
			[623] = "Hydross the Unstable",
			[624] = "The Lurker Below",
			[625] = "Leotheras the Blind",
			[626] = "Fathom-Lord Karathress",
			[627] = "Morogrim Tidewalker",
			[628] = "Lady Vashj"
		},

		-- The Eye
		[749] = {
			[730] = "Al'ar",
			[731] = "Void Reaver",
			[732] = "High Astromancer Solarian",
			[733] = "Kael'thas Sunstrider"
		},

		-- The Battle for Mount Hyjal
		[750] = {
			[618] = "Rage Winterchill",
			[619] = "Anetheron",
			[620] = "Kaz'rogal",
			[621] = "Azgalor",
			[622] = "Archimonde"
		},

		-- Black Temple
		[751] = {
			[601] = "High Warlord Naj'entus",
			[602] = "Supremus",
			[603] = "Shade of Akama",
			[604] = "Teron Gorefiend",
			[605] = "Gurtogg Bloodboil",
			[606] = "Reliquary of Souls",
			[607] = "Mother Shahraz",
			[608] = "The Illidari Council",
			[609] = "Illidan Stormrage"
		},

		-- Sunwell Plateau
		[752] = {
			[724] = "Kalecgos",
			[725] = "Brutallus",
			[726] = "Felmyst",
			[727] = "Eredar Twins",
			[728] = "M'uru",
			[729] = "Kil'jaeden"
		}
	},
	Wrath = {
		-- Vault of Archavon
		[753] = {
			[1126] = "Archavon the Stone Watcher",
			[1127] = "Emalon the Storm Watcher",
			[1128] = "Koralon the Flame Watcher",
			[1129] = "Toravon the Ice Watcher"
		},

		-- The Obsidian Sanctum
		[755] = {
			-- Check for missing encounterIDs
			[1093] = "Vesperon",
			[1092] = "Tenebron",
			[1091] = "Shadron",
			[1090] = "Sartharion",
		},

		-- Naxxramas
		[754] = {
			[1107] = "Anub'Rekhan",
			[1110] = "Grand Widow Faerlina",
			[1116] = "Maexxna",
			[1117] = "Noth the Plaguebringer",
			[1112] = "Heigan the Unclean",
			[1115] = "Loatheb",
			[1113] = "Instructor Razuvious",
			[1109] = "Gothik the Harvester",
			[1121] = "The Four Horsemen",
			[1118] = "Patchwerk",
			[1111] = "Grobbulus",
			[1108] = "Gluth",
			[1120] = "Thaddius",
			[1119] = "Sapphiron",
			[1114] = "Kel'Thuzad"
		},

		-- The Eye of Eternity
		[756] = {
			[1094] = "Malygos"
		},

		-- Ulduar
		[759] = {
			[1132] = "Flame Leviathan",
			[1136] = "Ignis the Furnace Master",
			[1139] = "Razorscale",
			[1142] = "XT-002 Deconstructor",
			[1140] = "The Assembly of Iron",
			[1137] = "Kologarn",
			[1131] = "Auriaya",
			[1135] = "Hodir",
			[1141] = "Thorim",
			[1133] = "Freya",
			[1138] = "Mimiron",
			[1134] = "General Vezax",
			[1143] = "Yogg-Saron",
			[1130] = "Algalon the Observer"
		},

		-- Trial of the Crusader
		[757] = {
			[1088] = "Northrend Beasts",
			[1087] = "Lord Jaraxxus",
			[1086] = "Faction Champions",
			[1089] = "Val'kyr Twins",
			[1085] = "Anub'arak"
		},

		-- Onyxia's Lair
		[760] = {
			[1084] = "Onyxia"
		},

		-- Icecrown Citadel
		[758] = {
			[1101] = "Lord Marrowgar",
			[1100] = "Lady Deathwhisper",
			[1099] = "Icecrown Gunship Battle",
			[1096] = "Deathbringer Saurfang",
			[1097] = "Festergut",
			[1104] = "Rotface",
			[1102] = "Professor Putricide",
			[1095] = "Blood Council",
			[1103] = "Queen Lana'thel",
			[1098] = "Valithria Dreamwalker",
			[1105] = "Sindragosa",
			[1106] = "The Lich King"
		},

		-- The Ruby Sanctum
		[761] = {
			[1147] = "Baltharus the Warborn",
			[1148] = "General Zarithrian",
			[1149] = "Saviana Ragefire",
			[1150] = "Halion"
		}
	},
	Cata = {
		-- Baradin Hold
		[75] = {
			[1033] = "Argaloth",
			[1250] = "Occu'thar",
			[1332] = "Alizabal"
		},

		-- Blackwing Descent
		[73] = {
			[1027] = "Omnotron Defense System",
			[1024] = "Magmaw",
			[1022] = "Atramedes",
			[1023] = "Chimaeron",
			[1025] = "Maloriak",
			[1026] = "Nefarian's End"
		},

		-- Throne of the Four Winds
		[74] = {
			[1035] = "Conclave of Wind",
			[1034] = "Al'Akir"
		},

		-- The Bastion of Twilight
		[72] = {
			[1030] = "Halfus Wyrmbreaker",
			[1032] = "Theralion and Valiona",
			[1028] = "Ascendant Council",
			[1029] = "Cho'gall",
			--[1082] = "Sinestra", -- What is this?
			[1083] = "Sinestra"
		},

		-- Firelands
		[78] = {
			[1197] = "Beth'tilac",
			[1204] = "Lord Rhyolith",
			[1206] = "Alysrazor",
			[1205] = "Shannox",
			[1200] = "Baleroc",
			[1185] = "Majordomo Staghelm",
			[1203] = "Ragnaros"
		},

		-- Dragon Soul
		[187] = {
			[1292] = "Morchok",
			[1294] = "Warlord Zon'ozz",
			[1295] = "Yor'sahj the Unsleeping",
			[1296] = "Hagara",
			[1297] = "Ultraxion",
			[1298] = "Warmaster Blackhorn",
			[1291] = "Spine of Deathwing",
			[1299] = "Madness of Deathwing"
		}
	},
	MoP = {
		-- Mogu'shan Vaults
		[317] = {
			[1395] = "The Stone Guard",
			[1390] = "Feng the Accursed",
			[1434] = "Gara'jal the Spiritbinder",
			[1436] = "The Spirit Kings",
			[1500] = "Elegon",
			[1407] = "Will of the Emperor"
		},

		-- Heart of Fear
		[330] = {
			[1507] = "Imperial Vizier Zor'lok",
			[1504] = "Blade Lord Ta'yak",
			[1463] = "Garalon",
			[1498] = "Wind Lord Mel'jarak",
			[1499] = "Amber-Shaper Un'sok",
			[1501] = "Grand Empress Shek'zeer"
		},

		-- Terrace of Endless Spring
		[320] = {
			[1409] = "Protectors of the Endless",
			[1505] = "Tsulong",
			[1506] = "Lei Shi",
			[1431] = "Sha of Fear"
		},

		-- Throne of Thunder
		[362] = {
			[1577] = "Jin'rokh the Breaker",
			[1575] = "Horridon",
			[1570] = "Council of Elders",
			[1565] = "Tortos",
			[1578] = "Megaera",
			[1573] = "Ji-Kun",
			[1572] = "Durumu the Forgotten",
			[1574] = "Primordius",
			[1576] = "Dark Animus",
			[1559] = "Iron Qon",
			[1560] = "Twin Consorts",
			[1579] = "Lei Shen",
			-- What is the difference here?
			[1580] = "Ra-den",
			[1581] = "Ra-den"
		},

		-- Siege of Orgrimmar
		[369] = {
			[1602] = "Immerseus",
			[1598] = "Fallen Protectors",
			[1624] = "Norushen",
			[1604] = "Sha of Pride",
			[1622] = "Galakras",
			[1600] = "Iron Juggernaut",
			[1606] = "Kor'kron Dark Shaman",
			[1603] = "General Nazgrim",
			[1595] = "Malkorok",
			[1594] = "Spoils of Pandaria",
			[1599] = "Thok the Bloodthirsty",
			[1601] = "Siegecrafter Blackfuse",
			[1593] = "Paragons of the Klaxxi",
			[1623] = "Garrosh Hellscream"
		}
	},
	WoD = {
		-- Highmaul
		[477] = {
			[1721] = "Kargath Bladefist",
			[1706] = "The Butcher",
			[1722] = "Tectus, The Living Mountain",
			[1720] = "Brackenspore",
			[1719] = "Twin Ogron",
			[1723] = "Ko'ragh",
			[1705] = "Imperator Mar'gok"
		},

		-- Blackrock Foundry
		[457] = {
			[1696] = "Oregorger the Devourer",
			[1693] = "Hans'gar & Franzok",
			[1694] = "Beastlord Darmac",
			[1691] = "Gruul",
			[1689] = "Flamebender Ka'graz",
			[1692] = "Operator Thogar",
			[1690] = "Blast Furnace",
			[1713] = "Kromog, Legend of the Mountain",
			[1695] = "The Iron Maidens",
			[1704] = "Blackhand"
		},

		-- Hellfire Citadel
		[669] = {
			[1778] = "Hellfire Assault",
			[1785] = "Iron Reaver",
			[1787] = "Kormrok",
			[1798] = "Hellfire High Council",
			[1786] = "Kilrogg Deadeye",
			[1783] = "Gorefiend",
			[1788] = "Shadow-Lord Iskar",
			[1794] = "Socrethar the Eternal",
			[1777] = "Fel Lord Zakuun",
			[1800] = "Xhul'horac",
			[1784] = "Tyrant Velhari",
			[1795] = "Mannoroth",
			[1799] = "Archimonde"
		}
	},
	Legion = {
		-- The Emerald Nightmare
		[768] = {
			[1841] = "Ursoc",
			[1853] = "Nythendra",
			[1854] = "Dragons of Nightmare",
			[1864] = "Xavius",
			[1873] = "Il'gynoth, The Heart of Corruption",
			[1876] = "Elerethe Renferal",
			[1877] = "Cenarius"
		},

		-- Trial of Valor
		[861] = {
			[1958] = "Odyn",
			[1962] = "Guarm",
			[2008] = "Helya"
		},

		-- The Nighthold
		[786] = {
			[1842] = "Krosus",
			[1849] = "Skorpyron",
			[1862] = "Tichondrius",
			[1863] = "Star Augur Etraeus",
			[1865] = "Chronomatic Anomaly",
			[1866] = "Gul'dan",
			[1867] = "Trilliax",
			[1871] = "Spellblade Aluriel",
			[1872] = "Grand Magistrix Elisande",
			[1886] = "High Botanist Tel'arn"
		},

		-- Tomb of Sargeras
		[875] = {
			[2032] = "Goroth",
			[2036] = "Harjatan",
			[2037] = "Mistress Sassz'ine",
			[2038] = "Fallen Avatar",
			[2048] = "Demonic Inquisition",
			[2050] = "Sisters of the Moon",
			[2051] = "Kil'jaeden",
			[2052] = "Maiden of Vigilance",
			[2054] = "The Desolate Host"
		},

		-- Antorus, the Burning Throne
		[946] = {
			[2076] = "Garothi Worldbreaker",
			[2074] = "Felhounds of Sargeras",
			[2070] = "Antoran High Command",
			[2064] = "Portal Keeper Hasabel",
			[2075] = "Eonar the Life-Binder", -- The Defense of Eonar
			[2082] = "Imonar the Soulhunter",
			[2088] = "Kin'garoth",
			[2069] = "Varimathras",
			[2073] = "The Coven of Shivarra",
			[2063] = "Aggramar",
			[2092] = "Argus the Unmaker"
		}
	},
	BfA = {
		-- Uldir
		[1031] = {
			[2144] = "Taloc",
			[2141] = "MOTHER",
			[2128] = "Fetid Devourer",
			[2136] = "Zek'voz, Herald of Nzoth",
			[2134] = "Vectis",
			[2145] = "Zul, Reborn",
			[2135] = "Mythrax the Unraveler",
			[2122] = "G'huun"
		},

		-- Battle of Dazar'alor
		[1176] = {
			[2265] = "Champion of the Light",
			[2285] = "Jadefire Masters (A)",
			[2263] = "Grong, the Jungle Lord (H)",
			[2284] = "Grong, the Revenant (A)",
			[2266] = "Jadefire Masters (H)",
			[2271] = "Opulence",
			[2268] = "Conclave of the Chosen",
			[2272] = "King Rastakhan",
			[2276] = "High Tinker Mekkatorque",
			[2280] = "Stormwall Blockade",
			[2281] = "Lady Jaina Proudmoore"
		},

		-- Crucible of Storms
		[1177] = {
			[2269] = "The Restless Cabal",
			[2273] = "Uu'nat, Harbinger of the Void"
		},

		-- The Eternal Palace
		[1179] = {
			[2298] = "Abyssal Commander Sivara",
			[2289] = "Blackwater Behemoth",
			[2305] = "Radiance of Azshara",
			[2304] = "Lady Ashvane",
			[2303] = "Orgozoa",
			[2311] = "The Queen's Court",
			[2293] = "Za'qul, Harbinger of Ny'alotha",
			[2299] = "Queen Azshara"
		},

		-- Ny'alotha, the Waking City
		[1180] = {
			[2329] = "Wrathion, the Black Emperor",
			[2327] = "Maut",
			[2334] = "The Prophet Skitra",
			[2328] = "Dark Inquisitor Xanesh",
			[2333] = "The Hivemind",
			[2335] = "Shad'har the Insatiable",
			[2343] = "Drest'agath",
			[2345] = "Il'gynoth, Corruption Reborn",
			[2336] = "Vexiona",
			[2331] = "Ra-den the Despoiled",
			[2337] = "Carapace of N'Zoth",
			[2344] = "N'Zoth the Corruptor"
		}
	},
	SL = {
		-- Castle Nathria
		[1190] = {
			[2398] = "Shriekwing",
			[2398] = "Huntsman Altimor",
			[2398] = "Sun King's Salvation",
			[2398] = "Artificer Xy'mox",
			[2398] = "Hungering Destroyer",
			[2398] = "Lady Inerva Darkvein",
			[2398] = "The Council of Blood",
			[2398] = "Sludgefist",
			[2398] = "Stone Legion Generals",
			[2398] = "Sire Denathrius"
		},

		-- Sanctum of Domination
		[1193] = {
			[2423] = "The Tarragrue",
			[2423] = "The Eye of the Jailer",
			[2423] = "The Nine",
			[2423] = "Remnant of Ner'zhul",
			[2423] = "Soulrender Dormazain",
			[2423] = "Painsmith Raznal",
			[2423] = "Guardian of the First Ones",
			[2423] = "Fatescribe Roh-Kalo",
			[2423] = "Kel'Thuzad",
			[2423] = "Sylvanas Windrunner"
		},

		-- Sepulcher of the First Ones
		[1195] = {
			[2512] = "Vigilant Guardian",
			[2512] = "Skolex, the Insatiable Ravener",
			[2512] = "Artificer Xy'mox",
			[2512] = "Dausegne, the Fallen Oracle",
			[2512] = "Prototype Pantheon",
			[2512] = "Lihuvim, Principal Architect",
			[2512] = "Halondrus the Reclaimer",
			[2512] = "Anduin Wrynn",
			[2512] = "Lords of Dread",
			[2512] = "Rygelon",
			[2512] = "The Jailer"
		}
	},
	DF = {
		-- Vault of the Incarnates
		[1200] = {
			[2587] = "Eranog",
			[2639] = "Terros",
			[2590] = "The Primal Council",
			[2592] = "Sennarth, the Cold Breath",
			[2635] = "Dathea, Ascended",
			[2605] = "Kurog Grimtotem",
			[2614] = "Broodkeeper Diurna",
			[2607] = "Raszageth the Storm-Eater",
		},

		-- Aberrus, the Shadowed Crucible
		[1208] = {
			[2688] = "Kazzara, the Hellforged",
			[2687] = "The Amalgamation Chamber",
			[2693] = "The Forgotten Experiments",
			[2682] = "Assault of the Zaqali",
			[2680] = "Rashok, the Elder",
			[2689] = "The Vigilant Steward, Zskarn",
			[2683] = "Magmorax",
			[2684] = "Echo of Neltharion",
			[2685] = "Scalecommander Sarkareth",
		},

		-- Amirdrassil, the Dream's Hope
		[1207] = {
			[2820] = "Gnarlroot",
			[2709] = "Igira the Cruel",
			[2737] = "Volcoross",
			[2728] = "Council of Dreams",
			[2731] = "Larodar, Keeper of the Flame",
			[2708] = "Nymue, Weaver of the Cycle",
			[2824] = "Smolderon",
			[2786] = "Tindral Sageswift, Seer of the Flame",
			[2677] = "Fyrakk the Blazing",
		}
	},
	TWW = {
		-- Nerub-ar Palace
		[1273] = {
			[2902] = "Ulgrax the Devourer",
			[2917] = "The Bloodbound Horror",
			[2898] = "Sikran, Captain of the Sureki",
			[2918] = "Rasha'nan",
			[2919] = "Broodtwister Ovi'nax",
			[2920] = "Nexus-Princess Ky'veza",
			[2921] = "The Silken Court",
			[2922] = "Queen Ansurek",
		}
	}
}
for _, v in pairs(RaidEncounterIDs) do
	for instanceID, encounterIDs in pairs(v) do
		ns.RaidEncounterIDs[instanceID] = encounterIDs
	end
end


--[[----------------------------------------------------------------------------
	These get boss frame but ain't the real bosses or interesting adds or needs
	to be excluded from the graphs for any other reason.

	[creatureID] = "Additional Monster Name"
	List of unique boss adds with matching name.
----------------------------------------------------------------------------]]--
local BossAdds = {
	TBC = {
		-- Karazhan
			--[[
			-- Opera Hall START
				[17543] = "Strawman", -- Wizard of Oz P1
				[17546] = "Roar", -- Wizard of Oz P1
				[17547] = "Tinhead", -- Wizard of Oz P1
			-- Opera Hall END
			[17229] = "Kil'rek", -- Terestian Illhoof
			-- Chess Event START
				[17211] = "Human Footman",
				[17469] = "Orc Grunt",
				[21160] = "Conjured Water Elemental",
				[21726] = "Summoned Daemon",
				[21664] = "Human Charger",
				[21748] = "Orc Wolf",
				[21682] = "Human Cleric",
				[21747] = "Orc Necrolyte",
				[21683] = "Human Conjurer",
				[21750] = "Orc Warlock",
			-- Chess Event END
			]]--

		-- Gruul's Lair
			--[[
			[18832] = "Krosh Firehand", -- High King Maulgar
			[18834] = "Olm the Summoner", -- High King Maulgar
			[18835] = "Kiggler the Crazed", -- High King Maulgar
			[18836] = "Blindeye the Seer", -- High King Maulgar
			]]--

		-- Magtheridon's Lair
			--[[
			[17256] = "Hellfire Channeler",
			]]--

		-- Serpentshrine Cavern
			--[[
			[21964] = "Fathom-Guard Caribdis", -- Fathom-Lord Karathress
			[21965] = "Fathom-Guard Tidalvess", -- Fathom-Lord Karathress
			[21966] = "Fathom-Guard Sharkkis", -- Fathom-Lord Karathress
			[21958] = "Enchanted Elemental", -- Lady Vashj
			[22009] = "Tainted Elemental", -- Lady Vashj
			[22055] = "Coilfang Elite", -- Lady Vashj
			[22056] = "Coilfang Strider", -- Lady Vashj
			]]--

		-- The Eye
			--[[
			[20060] = "Lord Sanguinar", -- Kael'thas Sunstrider
			[20062] = "Grand Astromancer Capernian", -- Kael'thas Sunstrider
			[20063] = "Master Engineer Telonicus", -- Kael'thas Sunstrider
			[20064] = "Thaladred the Darkener", -- Kael'thas Sunstrider
			[21268] = "Netherstrand Longbow", -- Kael'thas Sunstrider
			[21269] = "Devastation", -- Kael'thas Sunstrider
			[21270] = "Cosmic Infuser", -- Kael'thas Sunstrider
			[21271] = "Infinity Blades", -- Kael'thas Sunstrider
			[21272] = "Warp Slicer", -- Kael'thas Sunstrider
			[21273] = "Phaseshift Bulwark", -- Kael'thas Sunstrider
			[21274] = "Staff of Disintegration", -- Kael'thas Sunstrider
			]]--

		-- Black Temple
			[22997] = "Flame of Azzinoth", -- Illidan Stormrage

		-- Sunwell Plateau
			--[[
			[25588] = "Hand of the Deceiver", -- Kil'jaeden
			[25502] = "Shield Orb", -- Kil'jaeden
			[25708] = "Sinister Reflection" -- Kil'jaeden
			]]--
	},
	Wrath = {
		-- Vault of Archavon
			--[[
			[33998] = "Tempest Minion", -- Emalon the Storm Watcher (Surrounding boss)
			[34049] = "Tempest Minion", -- Emalon the Storm Watcher (Summoned during encounter)
			[38456] = "Frozen Orb", -- Toravon the Ice Watcher
			]]--

		-- Naxxramas
			--[[
			[16573] = "Crypt Guard", -- Anub'Rekhan
			[16506] = "Naxxramas Worshipper", -- Grand Widow Faerlina
			[16286] = "Spore", -- Loatheb
			[16803] = "Death Knight Understudy", -- Instructor Razuvious
			[16124] = "Unrelenting Trainee", -- Gothik the Harvester
			[16127] = "Spectral Trainee", -- Gothik the Harvester
			[16125] = "Unrelenting Death Knight", -- Gothik the Harvester
			[16148] = "Spectral Death Knight", -- Gothik the Harvester
			[16126] = "Unrelenting Rider", -- Gothik the Harvester
			[16149] = "Spectral Horse", -- Gothik the Harvester
			[16150] = "Spectral Rider", -- Gothik the Harvester
			[16360] = "Zombie Chow", -- Gluth
			[23561] = "Soldier of the Frozen Wastes", -- Kel'Thuzad
			[23562] = "Unstoppable Abomination", -- Kel'Thuzad
			[23563] = "Soul Weaver", -- Kel'Thuzad
			[16441] = "Guardian of Icecrown", -- Kel'Thuzad
			]]--

		-- The Eye of Eternity
			--[[
			[30245] = "Nexus Lord", -- Malygos
			[30249] = "Scion of Eternity", -- Malygos
			]]--

		-- Ulduar
			--[[
			[33121] = "Iron Construct", -- Ignis the Furnace Master
			[33388] = "Dark Rune Guardian", -- Razorscale
			[33453] = "Dark Rune Watcher", -- Razorscale
			[33846] = "Dark Rune Sentinel", -- Razorscale
			[33343] = "XS-013 Scrapbot", -- XT-002 Deconstructor
			[33346] = "XE-321 Boombot", -- XT-002 Deconstructor
			[33768] = "Rubble", -- Kologarn
			[34014] = "Sanctum Sentry", -- Auriaya (Patroling with her)
			[34035] = "Feral Defender", -- Auriaya
			-- Thorim START
				-- On Pull
				[32882] = "Jormungar Behemoth",
				[32883] = "Captured Mercenary Soldier",
				[32886] = "Dark Rune Acolyte",
				[32907] = "Captured Mercenary Captain",

				-- Arena
				[32922] = "Dark Rune Champion",
				[32923] = "Dark Rune Commoner",
				[32924] = "Dark Rune Evoker",
				[32925] = "Dark Rune Warbringer",

				-- Gauntlet
				[32872] = "Runic Colossus",
				[32873] = "Ancient Rune Giant",
				[32874] = "Iron Ring Guard",
				[33110] = "Dark Rune Acolyte",
			-- Thorim END
			[32916] = "Snaplasher", -- Freya
			[32918] = "Detonating Lasher", -- Freya
			[32919] = "Storm Lasher", -- Freya
			[33202] = "Ancient Water Spirit", -- Freya
			[33203] = "Ancient Conservator", -- Freya
			[33228] = "Eonar's Gift", -- Freya
			[34362] = "Proximity Mine", -- Mimiron P1
			[33836] = "Bomb Bot", -- Mimiron P3
			[33855] = "Junk Bot", -- Mimiron P3
			[34057] = "Assault Bot", -- Mimiron P3
			[34147] = "Emergency Fire Bot", -- Mimiron P3 (HM)
			[33488] = "Saronite Vapors", -- General Vezax
			[33524] = "Saronite Animus", -- General Vezax (HM)
			[33136] = "Guardian of Yogg-Saron", -- Yogg-Saron P2
			[33983] = "Constrictor Tentacle", -- Yogg-Saron P2
			[33966] = "Crusher Tentacle", -- Yogg-Saron P2
			[33985] = "Corruptor Tentacle", -- Yogg-Saron P2
			[33716] = "Influence Tentacle", -- Yogg-Saron P2 (The Mind's Eye)
			[33988] = "Immortal Guardian", -- Yogg-Saron P3
			[32955] = "Collapsing Star", -- Algalon the Observer
			[33052] = "Living Constellation", -- Algalon the Observer
			[33089] = "Dark Matter", -- Algalon the Observer
			]]--

		-- Trial of the Crusader
			--[[
			[34800] = "Snobold Vassal", -- Northrend Beasts P1
			[34815] = "Felflame Infernal", -- Lord Jaraxxus
			[34826] = "Mistress of Pain", -- Lord Jaraxxus
			-- Faction Champions START
				-- Horde
				[35465] = "Zhaagrym", -- Harkzog's Demon pet
				[35610] = "Cat", -- Ruj'kah's Beast pet
			-- Faction Champions END
			[34606] = "Frost Sphere", -- Anub'arak
			[34607] = "Nerubian Burrower", -- Anub'arak (Phase 1)
			[34605] = "Swarm Scarab", --Anub'arak (Intermission)
			]]--

		-- Onyxia's Lair
			--[[
			[11262] = "Onyxian Whelp", -- Onyxia P2
			[36561] = "Onyxian Lair Guard", -- Onyxia P2
			]]--

		-- Icecrown Citadel
			--[[
			[37890] = "Cult Fanatic", -- Lady Deathwhisper
			[37890] = "Deformed Fanatic", -- Lady Deathwhisper
			[37890] = "Reanimated Fanatic", -- Lady Deathwhisper
			[37949] = "Cult Adherent", -- Lady Deathwhisper
			[37949] = "Empowered Adherent", -- Lady Deathwhisper
			[37949] = "Reanimated Adherent", -- Lady Deathwhisper
			[38508] = "Blood Beast", -- Deathbringer Saurfang
			[37562] = "Gas Cloud", -- Professor Putricide
			[37697] = "Volatile Ooze", -- Professor Putricide
			[38369] = "Dark Nucleus", -- Blood Council
			[38454] = "Kinetic Bomb", -- Blood Council
			[36791] = "Blazing Skeleton", -- Valithria Dreamwalker
			[37863] = "Suppresser", -- Valithria Dreamwalker
			[37868] = "Risen Archmage", -- Valithria Dreamwalker
			[37886] = "Gluttonous Abomination", -- Valithria Dreamwalker
			[37907] = "Rot Worm", -- Valithria Dreamwalker
			[37934] = "Blistering Zombie", -- Valithria Dreamwalker
			[36609] = "Val'kyr Shadowguard", -- The Lich King
			[36633] = "Ice Sphere", -- The Lich King
			[36701] = "Raging Spirit", -- The Lich King
			[37695] = "Drudge Ghoul", -- The Lich King
			[37698] = "Shambling Horror", -- The Lich King
			[37799] = "Vile Spirit", -- The Lich King
			]]--

		-- The Ruby Sanctum
			--[[
			[39814] = "Onyx Flamecaller" -- General Zarithrian
			]]--
	},
	Cata = {
		-- Blackwing Descent
			[41948] = "Chromatic Prototype", -- Nefarian P2

		-- The Bastion of Twilight
			[46277] = "Calen", -- Sinestra

		-- Firelands
			[53509] = "Voracious Hatchling", -- Alysrazor
			[53898] = "Voracious Hatchling", -- Alysrazor
			[53694] = "Riplimb", -- Shannox
			[53695] = "Rageface", -- Shannox
			[53231] = "Lava Scion", -- Ragnaros

		-- Dragon Soul
			[55862] = "Acidic Globule", -- Yor'sahj the Unsleeping
			[55863] = "Shadowed Globule", -- Yor'sahj the Unsleeping
			[55864] = "Glowing Globule", -- Yor'sahj the Unsleeping
			[55865] = "Crimson Globule", -- Yor'sahj the Unsleeping
			[55866] = "Cobalt Globule", -- Yor'sahj the Unsleeping
			[55867] = "Dark Globule", -- Yor'sahj the Unsleeping
			[56598] = "The Skyfire" -- Warmaster Blackhorn
	},
	MoP = {
		-- Mogu'shan Vaults

		-- Heart of Fear
			[63053] = "Garalon's Leg", -- Garalon
			[62447] = "The Kor'thik", -- Wind Lord Mel'jarak
			[62451] = "The Sra'thik", -- Wind Lord Mel'jarak
			[62452] = "The Zar'thik", -- Wind Lord Mel'jarak
			[62711] = "Amber Monstrosity", -- Amber-Shaper Un'sok

		-- Terrace of Endless Spring

		-- Throne of Thunder
			[69374] = "War-God Jalak", -- Horridon
			[69480] = "Blessed Loa Spirit", -- Council of Elders
			[70212] = "Flaming Head", -- Megaera
			[70235] = "Frozen Head", -- Megaera
			[70247] = "Venomous Head", -- Megaera
			[70248] = "Arcane Head", -- Megaera
			[68079] = "Ro'shak", -- Iron Qon
			[68080] = "Quet'zal", -- Iron Qon
			[68081] = "Dam'ren", -- Iron Qon
			[68398] = "Static Shock Conduit", -- Lei Shen
			[68696] = "Diffusion Chain Conduit", -- Lei Shen
			[68697] = "Overcharge Conduit", -- Lei Shen
			[68698] = "Bouncing Bolt Conduit", -- Lei Shen

		-- Siege of Orgrimmar
			[71474] = "Embodied Despair", -- Fallen Protectors
			[71476] = "Embodied Misery", -- Fallen Protectors
			[71477] = "Embodied Gloom", -- Fallen Protectors
			[71478] = "Embodied Anguish", -- Fallen Protectors
			[71481] = "Embodied Sorrow", -- Fallen Protectors
			[71482] = "Embodied Desperation", -- Fallen Protectors
			[72302] = "Lady Jaina Proudmoore", -- Galakras (Alliance)
			[72311] = "King Varian Wrynn", -- Galakras (Alliance)
			[73910] = "Vereesa Windrunner", -- Galakras (Alliance)
			[72560] = "Lor'themar Theron", -- Galakras (Horde)
			[72561] = "Lady Sylvanas Windrunner", -- Galakras (Horde)
			[73909] = "Archmage Aethas Sunreaver", -- Galakras (Horde)
			[71606] = "Deactivated Missile Turret", -- Siegecrafter Blackfuse
			[71694] = "Deactivated Electromagnet", -- Siegecrafter Blackfuse
			[71751] = "Deactivated Laser Turret", -- Siegecrafter Blackfuse
			[71790] = "Disassembled Crawler Mines", -- Siegecrafter Blackfuse
			[71984] = "Siege Engineer" -- Garrosh Hellscream P1
	},
	WoD = {
		-- Highmaul
			[78884] = "Living Mushroom", -- Brackenspore
			[79092] = "Fungal Flesh-Eater", -- Brackenspore
			[77809] = "Arcane Aberration", -- Imperator Mar'gok
			[77877] = "Replicating Arcane Aberration", -- Imperator Mar'gok
			[77878] = "Fortified Arcane Aberration", -- Imperator Mar'gok
			[77879] = "Displacing Arcane Aberration", -- Imperator Mar'gok
			[78121] = "Gorian Warmage", -- Imperator Mar'gok
			[78549] = "Gorian Reaver", -- Imperator Mar'gok

		-- Blackrock Foundry
			[76874] = "Dreadwing", -- Beastlord Darmac
			[76884] = "Cruelfang", -- Beastlord Darmac
			[76945] = "Ironcrusher", -- Beastlord Darmac
			[76946] = "Faultline", -- Beastlord Darmac (Mythic)
			[76794] = "Cinder Wolf", -- Flamebender Ka'graz
			[77337] = "Aknor Steelbringer", -- Flamebender Ka'graz
			[77487] = "Grom'kar Firemender", -- Operator Thogar
			[78981] = "Iron Gunnery Sergeant", -- Operator Thogar
			[77342] = "Siegemaker", -- Blackhand
			[80646] = "Fiery Siegemaker", -- Blackhand (Mythic)
			[80654] = "Reinforced Siegemaker", -- Blackhand (Mythic)
			[80659] = "Supercharged Siegemaker", -- Blackhand (Mythic)
			[80660] = "Explosive Siegemaker", -- Blackhand (Mythic)

		-- Hellfire Citadel
			[90018] = "Hellfire Cannon", -- Hellfire Assault
			[90513] = "Fel Blood Globule", -- Kilrogg Deadeye
			[90521] = "Hulking Terror", -- Kilrogg Deadeye
			[93369] = "Hulking Terror", -- Kilrogg Deadeye
			[96077] = "Fel Blood Globule", -- Kilrogg Deadeye
			[90570] = "Gorebound Spirit", -- Gorefiend
			[91539] = "Fel Raven", -- Shadow-Lord Iskar Air P3
			[91541] = "Shadowfel Warden", -- Shadow-Lord Iskar Air P2 & P3
			[91543] = "Corrupted Talonpriest", -- Shadow-Lord Iskar Air P1-P3
			[93625] = "Phantasmal Resonance", -- Shadow-Lord Iskar (Mythic)
			[90296] = "Soulbound Construct", -- Socrethar the Eternal
			[94185] = "Vanguard Akkelion", -- Xhul'horac P1
			[94239] = "Omnus", -- Xhul'horac P2
			[90270] = "Ancient Enforcer", -- Tyrant Velhari P1 (90% HP)
			[90271] = "Ancient Harbinger", -- Tyrant Velhari P2 (60% HP)
			[90272] = "Ancient Sovereign", -- Tyrant Velhari P3 (30% HP)
			[91241] = "Doom Lord", --"Doom Lord Kaz'eth", -- Mannoroth P1-P3
			[91305] = "Fel Iron Summoner", -- Mannoroth P1
			[92208] = "Doomfire Spirit", -- Archimonde
			[92740] = "Hellfire Deathcaller", -- Archimonde
			[93615] = "Felborne Overfiend", -- Archimonde
			[96119] = "Source of Chaos", -- Archimonde P3 (Mythic)
	},
	Legion = {
		-- The Emerald Nightmare
			[105304] = "Dominator Tentacle", -- Il'gynoth
			[105591] = "Nightmare Horror", -- Il'gynoth
			[105468] = "Nightmare Ancient", -- Cenarius
			[105494] = "Rotten Drake", -- Cenarius
			[106482] = "Malfurion Stormrage", -- Cenarius
			[106667] = "Cleansed Ancient", -- Cenarius
			[103695] = "Corruption Horror", -- Xavius
			[104592] = "Nightmare Tentacle", -- Xavius

		-- Trial of Valor
			[114360] = "Hyrja", -- Odyn
			[114361] = "Hymdall", -- Odyn
			[114709] = "Grimelord", -- Helya
			[114809] = "Night Watch Mariner", -- Helya
			[114900] = "Gripping Tentacle", -- Helya (Mythic)

		-- The Nighthold
			[104676] = "Waning Time Particle", -- Chronomatic Anomaly
			[104880] = "Thing That Should Not Be", -- Star Augur Etraeus
			[105299] = "Recursive Elemental", -- Grand Magistrix Elisande
			[105301] = "Expedient Elemental", -- Grand Magistrix Elisande
			[104534] = "D'zorykx the Trapper", -- Gul'dan
			[104536] = "Inquisitor Vethriz", -- Gul'dan
			[104537] = "Fel Lord Kuraz'mal", -- Gul'dan
			[105295] = "Azagrim", -- Gul'dan
			[106545] = "Empowered Eye of Gul'dan", -- Gul'dan
			[107232] = "Beltheris", -- Gul'dan
			[107233] = "Dalvengyr", -- Gul'dan

		-- Tomb of Sargeras
			[119950] = "Brimstone Infernal", -- Goroth (Mythic)
			[116569] = "Razorjaw Wavemender", -- Harjatan
			[121071] = "Elder Murk-Eye", -- Harjatan
			[119205] = "Moontalon", -- Sisters of the Moon
			[117264] = "Maiden of Valor", -- Fallen Avatar
			[119107] = "Wailing Reflection", -- Kil'jaeden

		-- Antorus, the Burning Throne
			[122778] = "Annihilator", -- Garothi Worldbreaker
			[122773] = "Decimator", -- Garothi Worldbreaker
			[122211] = "Vulcanar", -- Portal Keeper Hasabel
			[122212] = "Lady Dacidion", -- Portal Keeper Hasabel
			[122213] = "Lord Eilgar", -- Portal Keeper Hasabel
			[122500] = "Essence of Eonar", -- Eonar the Life-Binder
			[123760] = "Fel-Infused Destructor", -- Eonar the Life-Binder
			[125429] = "Paraxis Inquisitor", -- Eonar the Life-Binder (Mythic)
			[123906] = "Garothi Annihilator", -- Kin'garoth
			[123921] = "Garothi Decimator", -- Kin'garoth
			[123929] = "Garothi Demolisher", -- Kin'garoth
			[121985] = "Flame of Taeshalach", -- Aggramar
			[129386] = "Withered Gift of the Lifebinder", -- Argus the Unmaker
			[125886] = "Khaz'goroth" -- Argus the Unmaker
	},
	BfA = {
		-- Uldir
			[136429] = "Chamber 01", -- MOTHER
			[137022] = "Chamber 02", -- MOTHER
			[137023] = "Chamber 03", -- MOTHER
			[133492] = "Corruption Corpuscle", -- Fetid Devourer
			[134726] = "Projection of C'thun", -- Zek'voz, Herald of Nzoth
			[135129] = "Projection of Yogg-Saron", -- Zek'voz, Herald of Nzoth
			[135824] = "Nerubian Voidweaver", -- Zek'voz, Herald of Nzoth
			[135888] = "Warped Projection", -- Zek'voz, Herald of Nzoth
			[135016] = "Plague Amalgam", -- Vectis
			[139051] = "Nazmani Crusher", -- Zul, Reborn
			[139057] = "Nazmani Bloodhexer", -- Zul, Reborn
			[139381] = "N'raqi Destroyer", -- Mythrax the Unraveler
			[138324] = "Xalzaix", -- Mythrax the Unraveler (Mythic)
			-- What is the difference between these? Why do we need two creatureIDs?
			[138529] = "Dark Young", -- G'huun
			[134635] = "Dark Young", -- G'huun
			[134590] = "Blightspreader Tendril", -- G'huun (Heroic)
			[134118] = "Reorigination Drive", -- G'huun
			[134010] = "Gibbering Horror", -- G'huun

		-- Battle of Dazar'alor
			[147895] = "Rezani Disciple", -- Champion of the Light
			[147896] = "Zandalari Crusader", -- Champion of the Light
			[144998] = "Death Specter", -- Grong
			[145273] = "The Hand of In'zashi", -- Opulence
			[145274] = "Yalat's Bulwark", -- Opulence
			[146320] = "Prelate Za'lan", -- King Rastakhan
			[146322] = "Siegebreaker Roka", -- King Rastakhan
			[146326] = "Headhunter Gal'wana", -- King Rastakhan (Heroic)
			[146491] = "Phantom of Retribution", -- King Rastakhan
			[146492] = "Phantom of Rage", -- King Rastakhan
			[146493] = "Phantom of Slaughter", -- King Rastakhan (Heroic)
			[146251] = "Sister Katherine", -- Stormwall Blockade
			[146253] = "Brother Joseph", -- Stormwall Blockade
			[147180] = "Kul Tiran Corsair", -- Lady Jaina Proudmoore
			[147531] = "Kul Tiran Corsair", -- Lady Jaina Proudmoore
			[148890] = "Wall of Ice", -- Lady Jaina Proudmoore
			[149144] = "Jaina's Tide Elemental", -- Lady Jaina Proudmoore

		-- Crucible of Storms
			[144996] = "Visage from Beyond", -- The Restless Cabal
			[145491] = "Ocean Rune", -- The Restless Cabal
			[146496] = "Tempest Caller", -- Uu'nat, Harbinger of the Void
			[146581] = "Void Stone", -- Uu'nat, Harbinger of the Void
			[146582] = "Trident of Deep Ocean", -- Uu'nat, Harbinger of the Void
			[146642] = "Ocean Rune", -- Uu'nat, Harbinger of the Void

		-- The Eternal Palace
			[152512] = "Stormwraith", -- Radiance of Azshara
			[152311] = "Zanj'ir Myrmidon", -- Orgozoa
			[152312] = "Azsh'ari Witch", -- Orgozoa
			[152313] = "Dreadcoil Hulk", -- Orgozoa
			[153335] = "Potent Spark", -- The Queen's Court
			[153059] = "Aethanel", -- Queen Azshara P1
			[153060] = "Cyranus", -- Queen Azshara P1
			[153064] = "Overzealous Hulk", -- Queen Azshara P1
			[153090] = "Lady Venomtongue", -- Queen Azshara P3
			[153091] = "Serena Scarscale", -- Queen Azshara P3

		-- Ny'alotha, the Waking City
			[156650] = "Dark Manifestation", -- Maut
			[157255] = "Aqir Ravager", -- The Hivemind
			[157229] = "Living Miasma", -- Shad'har the Insatiable
			[157612] = "Eye of Drest'agath", -- Drest'agath
			[157614] = "Tentacle of Drest'agath", -- Drest'agath
			[157613] = "Maw of Drest'agath", -- Drest'agath
			[158343] = "Organ of Corruption", -- Il'gynoth, Corruption Reborn
			[157467] = "Void Ascendant", -- Vexiona
			[157366] = "Void Hunter", -- Ra-den the Despoiled (Void-Phase)
			[157365] = "Crackling Stalker", -- Ra-den the Despoiled (Vita-Phase)
			[157442] = "Gaze of Madness", -- Carapace of N'Zoth (Heroic)
			[158376] = "Psychus", -- N'Zoth the Corruptor P1 & P2
			[158367] = "Basher Tentacle", -- N'Zoth the Corruptor P2
			[162933] = "Thought Harvester" -- N'Zoth the Corruptor P3
	},
	SL = {
		-- Castle Nathria

		-- Sanctum of Domination

		-- Sepulcher of the First Ones
	},
	DF = {
		-- Vault of the Incarnates

		-- Aberrus, the Shadowed Crucible

		-- Amirdrassil, the Dream's Hope
	},
	TWW = {
		-- Nerub-ar Palace
	}
}
for _, v in pairs(BossAdds) do
	for creatureID, addName in pairs(v) do
		ns.BossAdds[creatureID] = addName
	end
end


--[[----------------------------------------------------------------------------
	These are the bosses or major adds we are interested in.

	[creatureID] = "Boss Name"
	List of unique creatureIDs of the boss monsters with matching names.
----------------------------------------------------------------------------]]--
local RaidBosses = {
	Classic = {
		-- Molten Core
			[12118] = "Lucifron",
			[11982] = "Magmadar",
			[12259] = "Gehennas",
			[12057] = "Garr",
			[12264] = "Shazzrah",
			[12056] = "Baron Geddon",
			[12098] = "Sulfuron Harbinger",
			[11988] = "Golemagg the Incinerator",
			[12018] = "Majordomo Executus",
			[11502] = "Ragnaros",

		-- Blackwing Lair
			[12435] = "Razorgore the Untamed",
			[13020] = "Vaelastrasz the Corrupt",
			[12017] = "Broodlord Lashlayer",
			[11983] = "Firemaw",
			[14601] = "Ebonroc",
			[11981] = "Flamegor",
			[14020] = "Chromaggus",
			[11583] = "Nefarian",

		-- Ruins of Ahn'Qiraj
			[15348] = "Kurinnaxx",
			[15341] = "General Rajaxx",
			[15340] = "Moam",
			[15370] = "Buru the Gorger",
			[15369] = "Ayamiss the Hunter",
			[15339] = "Ossirian the Unscarred",

		-- Temple of Ahn'Qiraj
			[15263] = "The Prophet Skeram",
			[15511] = "Lord Kri", -- Silithid Royalty
			[15543] = "Princess Yauj", -- Silithid Royalty
			[15544] = "Vem", -- Silithid Royalty
			[15516] = "Battleguard Sartura",
			[15510] = "Fankriss the Unyielding",
			[15299] = "Viscidus",
			[15509] = "Princess Huhuran",
			[15275] = "Emperor Vek'nilash", -- Twin Emperors
			[15276] = "Emperor Vek'lor", -- Twin Emperors
			[15517] = "Ouro",
			[15589] = "Eye of C'Thun", -- C'thun P1
			[15727] = "C'Thun" -- C'thun P2
	},
	TBC = {
		-- Karazhan
			--[16151] = "Midnight", -- Attumen the Huntsman P1
			[16152] = "Attumen the Huntsman", -- Attumen the Huntsman P2
			[15687] = "Moroes",
			[16457] = "Maiden of Virtue",
			-- Opera Hall START
				[17535] = "Dorothee", -- Wizard of Oz P1
				[18168] = "The Crone", -- Wizard of Oz P2
			-- Opera Hall END
			[15691] = "The Curator",
			[16524] = "Shade of Aran",
			[15688] = "Terestian Illhoof",
			[15689] = "Netherspite",
			-- Chess Event START
				--[21684] = "King Llane", -- Chess Event
				--[21752] = "Warchief Blackhand", -- Chess Event
			-- Chess Event END
			[15690] = "Prince Malchezaar",
			[17225] = "Nightbane",

		-- Gruul's Lair
			[18831] = "High King Maulgar",
			[19044] = "Gruul the Dragonkiller",

		-- Magtheridon's Lair
			[17257] = "Magtheridon",

		-- Serpentshrine Cavern
			[21216] = "Hydross the Unstable",
			[21217] = "The Lurker Below",
			[21215] = "Leotheras the Blind",
			--[21875] = "Shadow of Leotheras", -- Leotheras the Blind P2
			[21214] = "Fathom-Lord Karathress",
			[21213] = "Morogrim Tidewalker",
			[21212] = "Lady Vashj",

		-- The Eye
			[19514] = "Al'ar",
			[19516] = "Void Reaver",
			[18805] = "High Astromancer Solarian",
			[19622] = "Kael'thas Sunstrider",

		-- The Battle for Mount Hyjal
			[17767] = "Rage Winterchill",
			[17808] = "Anetheron",
			[17888] = "Kaz'rogal",
			[17842] = "Azgalor",
			[17968] = "Archimonde",

		-- Black Temple
			[22887] = "High Warlord Naj'entus",
			[22898] = "Supremus",
			[22841] = "Shade of Akama",
			--[23191] = "Akama", -- Shade of Akama
			[22871] = "Teron Gorefiend",
			[22948] = "Gurtogg Bloodboil",
			[23418] = "Essence of Suffering", -- Reliquary of Souls P1
			[23419] = "Essence of Desire", -- Reliquary of Souls P2
			[23420] = "Essence of Anger", -- Reliquary of Souls P3
			[22947] = "Mother Shahraz",
			[22949] = "Gathios the Shatterer", -- The Illidari Council
			[22950] = "High Nethermancer Zerevor", -- The Illidari Council
			[22951] = "Lady Malande", -- The Illidari Council
			[22952] = "Veras Darkshadow", -- The Illidari Council
			[22917] = "Illidan Stormrage",

		-- Sunwell Plateau
			[24850] = "Kalecgos", -- Kalecgos
			[24892] = "Sathrovarr the Corruptor", -- Kalecgos
			[24882] = "Brutallus",
			[25038] = "Felmyst",
			[25165] = "Lady Sacrolash", -- Eredar Twins
			[25166] = "Grand Warlock Alythess", -- Eredar Twins
			--[25741] = "M'uru", -- M'uru P1
			[25840] = "Entropius", -- M'uru P2
			[25315] = "Kil'jaeden"
	},
	Wrath = {
		-- Vault of Archavon
			[31125] = "Archavon the Stone Watcher",
			[33993] = "Emalon the Storm Watcher",
			[35013] = "Koralon the Flame Watcher",
			[38433] = "Toravon the Ice Watcher",

		-- The Obsidian Sanctum
			[28860] = "Sartharion",
			[30449] = "Vesperon",
			[30451] = "Shadron",
			[30452] = "Tenebron",

		-- Naxxramas
			[15956] = "Anub'Rekhan",
			[15953] = "Grand Widow Faerlina",
			[15952] = "Maexxna",
			[15954] = "Noth the Plaguebringer",
			[15936] = "Heigan the Unclean",
			[16011] = "Loatheb",
			[16061] = "Instructor Razuvious",
			[16060] = "Gothik the Harvester",
			[16063] = "Sir Zeliek", -- The Four Horsemen
			[16064] = "Thane Korth'azz", -- The Four Horsemen
			[16065] = "Lady Blaumeux", -- The Four Horsemen
			[30549] = "Baron Rivendare", -- The Four Horsemen
			[16028] = "Patchwerk",
			[15931] = "Grobbulus",
			[15932] = "Gluth",
			--[15929] = "Stalagg", -- Thaddius P1
			--[15930] = "Feugen", -- Thaddius P1
			[15928] = "Thaddius",
			[15989] = "Sapphiron",
			[15990] = "Kel'Thuzad",

		-- The Eye of Eternity
			[28859] = "Malygos",

		-- Ulduar
			[33113] = "Flame Leviathan",
			[33118] = "Ignis the Furnace Master",
			[33186] = "Razorscale",
			[33293] = "XT-002 Deconstructor",
			--[33329] = "Heart of the Deconstructor", -- XT-002 Deconstructor
			[32857] = "Stormcaller Brundir", -- The Assembly of Iron
			[32867] = "Steelbreaker", -- The Assembly of Iron
			[32927] = "Runemaster Molgeim", -- The Assembly of Iron
			[32930] = "Kologarn",
			--[32933] = "Left Arm", -- Kologarn
			--[32934] = "Right Arm", -- Kologarn
			[33515] = "Auriaya",
			[32845] = "Hodir",
			[32865] = "Thorim",
			[32906] = "Freya",
			--[32913] = "Elder Ironbranch", -- Freya
			--[32914] = "Elder Stonebark", -- Freya
			--[32915] = "Elder Brightleaf", -- Freya
			--[33350] = "Mimiron",
			[33432] = "Leviathan Mk II", -- Mimiron P1/P4
			[33651] = "VX-001", -- Mimiron P2/P4
			[33670] = "Aerial Command Unit", -- Mimiron P3/P4
			[33271] = "General Vezax",
			[33134] = "Sara", -- Yogg-Saron P1
			[33288] = "Yogg-Saron", -- Yogg-Saron P2/P3
			--[33890] = "Brain of Yogg-Saron", -- Yogg-Saron P2 (The Mind's Eye)
			[32871] = "Algalon the Observer",

		-- Trial of the Crusader
			[34796] = "Gormok the Impaler", -- Northrend Beasts P1
			[34799] = "Dreadscale", -- Northrend Beasts P2
			[35144] = "Acidmaw", -- Northrend Beasts P2
			[34797] = "Icehowl", -- Northrend Beasts P3
			[34780] = "Lord Jaraxxus",
			-- Faction Champions START
				-- Horde
				--[34441] = "Vivienne Blackwhisper", -- Shadow Priest
				--[34444] = "Thrakgar", -- Resto Shaman
				--[34445] = "Liandra Suncaller", -- Holy Paladin
				--[34447] = "Caiphus the Stern", -- Discipline Priest
				--[34448] = "Ruj'kah", -- Hunter
				--[34449] = "Ginselle Blightslinger", -- Mage
				--[34450] = "Harkzog", -- Warlock
				--[34451] = "Birana Stormhoof", -- Horde Balance Druid
				--[34453] = "Narrhok Steelbreaker", -- Warrior
				--[34454] = "Maz'dinah", -- Rogue
				--[34455] = "Broln Stouthorn", -- Enhancement Shaman
				--[34456] = "Malithas Brightblade", -- Retribution Paladin
				--[34458] = "Gorgrim Shadowcleave", -- Death Knight
				--[34459] = "Erin Misthoof", -- Restoration Druid
			-- Faction Champions END
			[34496] = "Eydis Darkbane", -- Val'kyr Twins
			[34497] = "Fjola Lightbane", -- Val'kyr Twins
			[34564] = "Anub'arak",

		-- Onyxia's Lair
			[10184] = "Onyxia",

		-- Icecrown Citadel
			[36612] = "Lord Marrowgar",
			[36855] = "Lady Deathwhisper",
			[37215] = "Orgrim's Hammer", -- Icecrown Gunship Battle
			[37540] = "The Skybreaker", -- Icecrown Gunship Battle
			[37813] = "Deathbringer Saurfang",
			[36626] = "Festergut",
			[36627] = "Rotface",
			[36678] = "Professor Putricide",
			[37970] = "Prince Valanar", -- Blood Council
			[37972] = "Prince Keleseth", -- Blood Council
			[37973] = "Prince Taldaram", -- Blood Council
			[37955] = "Blood-Queen Lana'thel",
			[36789] = "Valithria Dreamwalker",
			[36853] = "Sindragosa",
			[36597] = "The Lich King",

		-- The Ruby Sanctum
			[39751] = "Baltharus the Warborn",
			[39747] = "Saviana Ragefire",
			[39746] = "General Zarithrian",
			[39863] = "Halion", -- Physical realm Halion (P1/P3)
			[40142] = "Halion" -- Twilight realm Halion (P2/P3)
	},
	Cata = {
		-- Baradin Hold
			[47120] = "Argaloth",
			[52363] = "Occu'thar",
			[55869] = "Alizabal",

		-- Blackwing Descent
			[42166] = "Arcanotron", -- Omnotron Defense System
			[42178] = "Magmatron", -- Omnotron Defense System
			[42179] = "Electron", -- Omnotron Defense System
			[42180] = "Toxitron", -- Omnotron Defense System
			[41570] = "Magmaw",
			[41442] = "Atramedes",
			[43296] = "Chimaeron",
			[41378] = "Maloriak",			
			[41270] = "Onyxia", -- Nefarian P1
			[41376] = "Nefarian",

		-- Throne of the Four Winds
			[45870] = "Anshal", -- Conclave of Wind
			[45871] = "Nezir", -- Conclave of Wind
			[45872] = "Rohash", -- Conclave of Wind
			[46753] = "Al'Akir",

		-- The Bastion of Twilight
			[44600] = "Halfus Wyrmbreaker",
			[45992] = "Valiona", -- Theralion and Valiona
			[45993] = "Theralion", -- Theralion and Valiona
			[43686] = "Ignacious", -- Ascendant Council
			[43687] = "Feludius", -- Ascendant Council
			[43688] = "Arion", -- Ascendant Council
			[43689] = "Terrastra", -- Ascendant Council
			[43735] = "Elementium Monstrosity", -- Ascendant Council
			[43324] = "Cho'gall",
			[45213] = "Sinestra",

		-- Firelands
			[52498] = "Beth'tilac",
			[52558] = "Lord Rhyolith",
			[52577] = "Left Foot", -- Lord Rhyolith
			[53087] = "Right Foot", -- Lord Rhyolith
			[52530] = "Alysrazor",
			[53691] = "Shannox",
			[53494] = "Baleroc",
			[52571] = "Majordomo Staghelm",
			[52409] = "Ragnaros",

		-- Dragon Soul
			[55265] = "Morchok",
			[57773] = "Kohcrom", -- Morchok (HC)
			[55308] = "Warlord Zon'ozz",
			[55312] = "Yor'sahj the Unsleeping",
			[55689] = "Hagara the Stormbinder",
			[55294] = "Ultraxion",
			[56427] = "Warmaster Blackhorn",
			[53879] = "Deathwing", -- Spine of Deathwing
			[56341] = "Burning Tendons", -- Spine of Deathwing
			[56167] = "Arm Tentacle", -- Madness of Deathwing (Ysera's platform)
			[56168] = "Wing Tentacle", -- Madness of Deathwing (Alexstrasza's & Kalecgos' platform, same creatureID for both)
			[56173] = "Deathwing", -- Madness of Deathwing P1
			[56471] = "Mutated Corruption", -- Madness of Deathwing
			[56846] = "Arm Tentacle", -- Madness of Deathwing (Nozdormu's platform)
			[57962] = "Deathwing" -- -- Madness of Deathwing P2
	},
	MoP = {
		-- Mogu'shan Vaults
			[59915] = "Jasper Guardian", -- The Stone Guard
			[60043] = "Jade Guardian", -- The Stone Guard
			[60047] = "Amethyst Guardian", -- The Stone Guard
			[60051] = "Cobalt Guardian", -- The Stone Guard
			[60009] = "Feng the Accursed",
			[60143] = "Gara'jal the Spiritbinder",
			[60709] = "Qiang the Merciless", -- The Spirit Kings
			[60710] = "Subetai the Swift", -- The Spirit Kings
			[60701] = "Zian of the Endless Shadow", -- The Spirit Kings
			[60708] = "Meng the Demented", -- The Spirit Kings
			[60410] = "Elegon",
			-- These didn't get recorded for some reason?
			-- Adding them here anyway since they get real Boss-unitframes
			[60399] = "Qin-xi", -- Will of the Emperor
			[60400] = "Jan-xi", -- Will of the Emperor

		-- Heart of Fear
			[62980] = "Imperial Vizier Zor'lok",
			[62543] = "Blade Lord Ta'yak",
			[63191] = "Garalon",
			[62397] = "Wind Lord Mel'jarak",
			[62511] = "Amber-Shaper Un'sok",
			[62837] = "Grand Empress Shek'zeer",

		-- Terrace of Endless Spring
			[60583] = "Protector Kaolan", -- Protectors of the Endless
			[60585] = "Elder Regail", -- Protectors of the Endless
			[60586] = "Elder Asani", -- Protectors of the Endless
			[62442] = "Tsulong",
			[62983] = "Lei Shi",
			[60999] = "Sha of Fear",

		-- Throne of Thunder
			[69465] = "Jin'rokh the Breaker",
			[68476] = "Horridon",
			[69078] = "Sul the Sandcrawler", -- Council of Elders
			[69131] = "Frost King Malakk", -- Council of Elders
			[69132] = "High Priestess Mar'li", -- Council of Elders
			[69134] = "Kazra'jin", -- Council of Elders
			[67977] = "Tortos",
			[68065] = "Megaera",
			--[70212] = "Flaming Head", -- Megaera
			--[70235] = "Frozen Head", -- Megaera
			--[70247] = "Venomous Head", -- Megaera
			--[70248] = "Arcane Head", -- Megaera
			[69712] = "Ji-Kun",
			[68036] = "Durumu the Forgotten",
			[69017] = "Primordius",
			[69427] = "Dark Animus",
			[68078] = "Iron Qon",
			--[68079] = "Ro'shak", -- Iron Qon
			--[68080] = "Quet'zal", -- Iron Qon
			--[68081] = "Dam'ren", -- Iron Qon
			[68904] = "Suen", -- Twin Consorts
			[68905] = "Lu'lin", -- Twin Consorts
			[68397] = "Lei Shen",
			[69473] = "Ra-den",

		-- Siege of Orgrimmar
			[71543] = "Immerseus",
			[71475] = "Rook Stonetoe", -- Fallen Protectors
			[71479] = "He Softfoot", -- Fallen Protectors
			[71480] = "Sun Tenderheart", -- Fallen Protectors
			[72276] = "Amalgam of Corruption", -- Norushen
			[71734] = "Sha of Pride",
			[72249] = "Galakras",
			[71466] = "Iron Juggernaut",
			[71858] = "Wavebinder Kardris", -- Kor'kron Dark Shaman
			[71859] = "Earthbreaker Haromm", -- Kor'kron Dark Shaman
			[71515] = "General Nazgrim",
			[71454] = "Malkorok",
			[71512] = "Mantid Spoils", -- Spoils of Pandaria
			[73720] = "Mogu Spoils", -- Spoils of Pandaria
			[73721] = "Mantid Spoils", -- Spoils of Pandaria
			[73722] = "Mogu Spoils", -- Spoils of Pandaria
			[71529] = "Thok the Bloodthirsty",
			[71504] = "Siegecrafter Blackfuse",
			[71152] = "Skeer the Bloodseeker", -- Paragons of the Klaxxi	1st
			[71153] = "Hisek the Swarmkeeper", -- Paragons of the Klaxxi	1st
			[71154] = "Ka'roz the Locust", -- Paragons of the Klaxxi		2nd
			[71155] = "Korven the Prime", -- Paragons of the Klaxxi			3rd
			[71156] = "Kaz'tik the Manipulator", -- Paragons of the Klaxxi	6th
			[71157] = "Xaril the Poisoned Mind", -- Paragons of the Klaxxi	5th
			[71158] = "Rik'kal the Dissector", -- Paragons of the Klaxxi	1st
			[71160] = "Iyyokuk the Lucid", -- Paragons of the Klaxxi		4th
			[71161] = "Kil'ruk the Wind-Reaver", -- Paragons of the Klaxxi	7th
			[71865] = "Garrosh Hellscream"
	},
	WoD = {
		-- Highmaul
			[78714] = "Kargath Bladefist",
			[77404] = "The Butcher",
			[78948] = "Tectus", -- Tectus, The Living Mountain
			[80551] = "Shard of Tectus", -- Tectus, The Living Mountain
			[80557] = "Mote of Tectus", -- Tectus, The Living Mountain
			[78491] = "Brackenspore",
			[78237] = "Phemos", -- Twin Ogron
			[78238] = "Pol", -- Twin Ogron
			[79015] = "Ko'ragh",
			[77428] = "Imperator Mar'gok",
			[78623] = "Cho'gall", -- Imperator Mar'gok (Mythic)

		-- Blackrock Foundry
			[77182] = "Oregorger", -- Oregorger the Devourer
			[76973] = "Hans'gar", -- Hans'gar & Franzok
			[76974] = "Franzok", -- Hans'gar & Franzok
			[76865] = "Beastlord Darmac",
			[76877] = "Gruul",
			[76814] = "Flamebender Ka'graz",
			[76906] = "Operator Thogar",
			[76806] = "Heart of the Mountain", -- Blast Furnace P3
			[76808] = "Heat Regulator", -- Blast Furnace P1
			[76809] = "Foreman Feldspar", -- Blast Furnace
			[76815] = "Primal Elementalist", -- Blast Furnace P2
			[77692] = "Kromog", -- Kromog, Legend of the Mountain
			[77231] = "Enforcer Sorka", -- The Iron Maidens
			[77477] = "Marak the Blooded", -- The Iron Maidens
			[77557] = "Admiral Gar'an", -- The Iron Maidens
			[77325] = "Blackhand",

		-- Hellfire Citadel
			[90019] = "Reinforced Hellfire Door", -- Hellfire Assault
			[93023] = "Siegemaster Mar'tak", -- Hellfire Assault
			[90284] = "Iron Reaver",
			[90435] = "Kormrok",
			[92142] = "Blademaster Jubei'thos", -- Hellfire High Council
			[92144] = "Dia Darkwhisper", -- Hellfire High Council
			[92146] = "Gurtogg Bloodboil", -- Hellfire High Council
			[90378] = "Kilrogg Deadeye",
			[90199] = "Gorefiend",
			[90316] = "Shadow-Lord Iskar",
			[92330] = "Soul of Socrethar", -- Socrethar the Eternal
			[90296] = "Soulbound Construct", -- Socrethar the Eternal
			[89890] = "Fel Lord Zakuun",
			[93068] = "Xhul'horac",
			[90269] = "Tyrant Velhari",
			[91349] = "Mannoroth",
			[91331] = "Archimonde"
	},
	Legion = {
		-- The Emerald Nightmare
			[102672] = "Nythendra",
			[105393] = "Il'gynoth", -- Il'gynoth, The Heart of Corruption
			[105906] = "Eye of Il'gynoth", -- Il'gynoth, The Heart of Corruption
			[106087] = "Elerethe Renferal",
			[100497] = "Ursoc",
			[102679] = "Ysondre", -- Dragons of Nightmare
			[102682] = "Lethon", -- Dragons of Nightmare
			[102683] = "Emeriss", -- Dragons of Nightmare
			[102681] = "Taerar", -- Dragons of Nightmare
			[104636] = "Cenarius",
			[103769] = "Xavius",

		-- Trial of Valor
			--[114360] = "Hyrja", -- Odyn
			--[114361] = "Hymdall", -- Odyn
			[114263] = "Odyn", -- Odyn
			[114323] = "Guarm",
			[114537] = "Helya",

		-- The Nighthold
			[102263] = "Skorpyron",
			[104415] = "Chronomatic Anomaly",
			[104288] = "Trilliax",
			[104881] = "Spellblade Aluriel",
			[103685] = "Tichondrius",
			[101002] = "Krosus",
			[104528] = "Arcanist Tel'arn", -- High Botanist Tel'arn
			[109038] = "Solarist Tel'arn", -- High Botanist Tel'arn
			[109041] = "Naturalist Tel'arn", -- High Botanist Tel'arn
			[109040] = "Arcanist Tel'arn", -- High Botanist Tel'arn (Mythic)
			[103758] = "Star Augur Etraeus",
			[106643] = "Elisande", -- Grand Magistrix Elisande
			[104154] = "Gul'dan",

		-- Tomb of Sargeras
			[115844] = "Goroth",
			[116689] = "Atrigan", -- Demonic Inquisition
			[116691] = "Belac", -- Demonic Inquisition
			[116407] = "Harjatan",
			[118518] = "Priestess Lunaspyre", -- Sisters of the Moon
			[118523] = "Huntress Kasparian", -- Sisters of the Moon
			[118374] = "Captain Yathae Moonstrike", -- Sisters of the Moon
			[115767] = "Mistress Sassz'ine",
			[118462] = "Soul Queen Dejahna", -- The Desolate Host
			[118460] = "Engine of Souls", -- The Desolate Host
			[119072] = "The Desolate Host", -- The Desolate Host
			[118289] = "Maiden of Vigilance",
			[116939] = "Fallen Avatar",
			[117269] = "Kil'jaeden",

		-- Antorus, the Burning Throne
			[122450] = "Garothi Worldbreaker",
			[122477] = "F'harg", -- Felhounds of Sargeras
			[122135] = "Shatug", -- Felhounds of Sargeras
			[122367] = "Admiral Svirax", -- Antoran High Command
			[122369] = "Chief Engineer Ishkar", -- Antoran High Command
			[122333] = "General Erodus", -- Antoran High Command
			[122104] = "Portal Keeper Hasabel",
			[124445] = "The Paraxis", -- Eonar the Life-Binder
			[124158] = "Imonar the Soulhunter",
			[122578] = "Kin'garoth",
			[122366] = "Varimathras",
			[122468] = "Noura, Mother of Flames", -- The Coven of Shivarra
			[122467] = "Asara, Mother of Night", -- The Coven of Shivarra
			[122469] = "Diima, Mother of Gloom", -- The Coven of Shivarra
			[125436] = "Thu'raya, Mother of the Cosmos", -- The Coven of Shivarra (Mythic)
			[121975] = "Aggramar",
			[124828] = "Argus the Unmaker"
	},
	BfA = {
		-- Uldir
			[137119] = "Taloc",
			[135452] = "MOTHER",
			[133298] = "Fetid Devourer",
			[134445] = "Zek'voz",
			[134442] = "Vectis",
			[138967] = "Zul",
			[134546] = "Mythrax the Unraveler",
			[132998] = "G'huun",

		-- Battle of Dazar'alor
			[144683] = "Ra'wani Kanae", -- Champion of the Light
			[144691] = "Ma'ra Grimfang", -- Jadefire Masters
			[144692] = "Anathos Firecaller", -- Jadefire Masters
			[144638] = "Grong the Revenant",
			[145261] = "Opulence",
			[144747] = "Pa'ku's Aspect", -- Conclave of the Chosen
			[144767] = "Gonk's Aspect", -- Conclave of the Chosen
			[144941] = "Akunda's Aspect", -- Conclave of the Chosen
			[144963] = "Kimbul's Aspect", -- Conclave of the Chosen
			[145616] = "King Rastakhan", -- King Rastakhan
			[145644] = "Bwonsamdi", -- King Rastakhan
			[144796] = "High Tinker Mekkatorque",
			--[146251] = "Sister Katherine", -- Stormwall Blockade
			--[146253] = "Brother Joseph", -- Stormwall Blockade
			[146256] = "Laminaria", -- Stormwall Blockade
			[146409] = "Lady Jaina Proudmoore",

		-- Crucible of Storms
			[144754] = "Fa'thuul the Feared", -- The Restless Cabal
			[144755] = "Zaxasj the Speaker", -- The Restless Cabal
			[145371] = "Uu'nat", -- Uu'nat, Harbinger of the Void

		-- The Eternal Palace
			[151881] = "Abyssal Commander Sivara",
			[150653] = "Blackwater Behemoth",
			[152364] = "Radiance of Azshara",
			[152236] = "Lady Ashvane",
			[152128] = "Orgozoa",
			[152852] = "Pashmar the Fanatical", -- The Queen's Court
			[152853] = "Silivaz the Zealous", -- The Queen's Court
			[150859] = "Za'qul", -- Za'qul, Harbinger of Ny'alotha
			[152910] = "Queen Azshara",

		-- Ny'alotha, the Waking City
			[156818] = "Wrathion, the Black Emperor",
			[156523] = "Maut",
			[157238] = "Prophet Skitra", -- The Prophet Skitra
			[156575] = "Dark Inquisitor Xanesh",
			[157253] = "Ka'zir", -- The Hivemind
			[157254] = "Tek'ris", -- The Hivemind
			[157231] = "Shad'har the Insatiable",
			[157602] = "Drest'agath",
			[158328] = "Il'gynoth, Corruption Reborn",
			[157354] = "Vexiona",
			[156866] = "Ra-den the Despoiled",
			[157439] = "Fury of N'Zoth", -- Carapace of N'Zoth
			[158041] = "N'Zoth the Corruptor"
	},
	SL = {
		-- Castle Nathria

		-- Sanctum of Domination

		-- Sepulcher of the First Ones
	},
	DF = {
		-- Vault of the Incarnates

		-- Aberrus, the Shadowed Crucible

		-- Amirdrassil, the Dream's Hope
	},
	TWW = {
		-- Nerub-ar Palace
	}
}
for _, v in pairs(RaidBosses) do
	for creatureID, bossName in pairs(v) do
		ns.RaidBosses[creatureID] = bossName
	end
end


--[[----------------------------------------------------------------------------
	Sort the list of recorded encounters in instances on the left side of the
	Frame according to this priority list. When adding new expansion packs, add
	number '1' to the front of all 'ORDER' numbers in table 'r' (lazy way) and
	make new separator with 'instanceID' key-value set to higher than previous
	expansion packs corresponding separator.

	Table ["r"] (list of Raid Instances)
		[instanceID] = ORDER
		Sort instanceIDs based on ORDER.

	Table ["e"] (list of Raid Encounters)
		[encounterID] = ORDER
		Sort encounterIDs inside their own instanceIDs based on ORDER.
----------------------------------------------------------------------------]]--
local orderTable = {
	["r"] = { -- Raid instances
		-- Classic
			[100000] = 11111111110, -- Separator
			[741] = 11111111111, -- Molten Core
			[742] = 11111111112, -- Blackwing Lair
			[743] = 11111111113, -- Ruins of Ahn'Qiraj
			[744] = 11111111114, -- Temple of Ahn'Qiraj
			[1301] = 11111111115, -- Blackrock Depths (WoW 20th Anniversary Update) 

		-- TBC
			[100001] = 1111111110, -- Separator
			[745] = 1111111111, -- Karazhan
			[746] = 1111111112, -- Gruul's Lair
			[747] = 1111111113, -- Magtheridon's Lair
			[748] = 1111111114, -- Serpentshrine Cavern
			[749] = 1111111115, -- The Eye
			[750] = 1111111116, -- The Battle for Mount Hyjal
			[751] = 1111111117, -- Black Temple
			[752] = 1111111118, -- Sunwell Plateau

		-- Wrath
			[100002] = 111111110, -- Separator
			[753] = 111111111, -- Vault of Archavon
			[755] = 111111112, -- The Obsidian Sanctum
			[754] = 111111113, -- Naxxramas
			[756] = 111111114, -- The Eye of Eternity
			[759] = 111111115, -- Ulduar
			[757] = 111111116, -- Trial of the Crusader
			[760] = 111111117, -- Onyxia's Lair
			[758] = 111111118, -- Icecrown Citadel
			[761] = 111111119, -- The Ruby Sanctum

		-- Cata
			[100003] = 11111110, -- Separator
			[75] = 11111111, -- Baradin Hold
			[73] = 11111112, -- Blackwing Descent
			[74] = 11111113, -- Throne of the Four Winds
			[72] = 11111114, -- The Bastion of Twilight
			[78] = 11111115, -- Firelands
			[187] = 11111116, -- Dragon Soul

		-- MoP
			[100004] = 1111110, -- Separator
			[317] = 1111111, -- Mogu'shan Vaults
			[330] = 1111112, -- Heart of Fear
			[320] = 1111113, -- Terrace of Endless Spring
			[362] = 1111114, -- Throne of Thunder
			[369] = 1111115, -- Siege of Orgrimmar

		-- WoD
			[100005] = 111110, -- Separator
			[477] = 111111, -- Highmaul
			[457] = 111112, -- Blackrock Foundry
			[669] = 111113, -- Hellfire Citadel

		-- Legion
			[100006] = 11110, -- Separator
			[768] = 11111, -- The Emerald Nightmare
			[861] = 11112, -- Trial of Valor
			[786] = 11113, -- The Nighthold
			[875] = 11114, -- Tomb of Sargeras
			[946] = 11115, -- Antorus, the Burning Throne

		-- BfA
			[100007] = 1110, -- Separator
			[1031] = 1111, -- Uldir
			[1176] = 1112, -- Battle of Dazar'alor
			[1177] = 1113, -- Crucible of Storms
			[1179] = 1114, -- The Eternal Palace
			[1180] = 1115, -- Ny'alotha, the Waking City

		-- SL
			[100008] = 110, -- Separator
			[1190] = 111, -- Castle Nathria
			[1193] = 112, -- Sanctum of Domination
			[1195] = 113, -- Sepulcher of the First Ones

		-- DF
			[100009] = 10, -- Separator
			[1200] = 11, -- Vault of the Incarnates
			[1208] = 12, -- Aberrus, the Shadowed Crucible
			[1207] = 13, -- Amirdrassil, the Dream's Hope

		-- TWW
			[100010] = 0, -- Separator
			[1273] = 1, -- Nerub-ar Palace
	},
	["e"] = { -- Encounters
		-- Classic
			-- Molten Core
				[663] = 1, -- "Lucifron"
				[664] = 2, -- "Magmadar"
				[665] = 3, -- "Gehennas"
				[666] = 4, -- "Garr"
				[667] = 5, -- "Shazzrah"
				[668] = 6, -- "Baron Geddon"
				[669] = 7, -- "Sulfuron Harbinger"
				[670] = 8, -- "Golemagg the Incinerator"
				[671] = 9, -- "Majordomo Executus"
				[672] = 10, -- "Ragnaros"

			-- Blackwing Lair
				[610] = 1, -- "Razorgore the Untamed"
				[611] = 2, -- "Vaelastrasz the Corrupt"
				[612] = 3, -- "Broodlord Lashlayer"
				[613] = 4, -- "Firemaw"
				[614] = 5, -- "Ebonroc"
				[615] = 6, -- "Flamegor"
				[616] = 7, -- "Chromaggus"
				[617] = 8, -- "Nefarian"

			-- Ruins of Ahn'Qiraj
				[718] = 1, -- "Kurinnaxx"
				[719] = 2, -- "General Rajaxx"
				[720] = 3, -- "Moam"
				[721] = 4, -- "Buru the Gorger"
				[722] = 5, -- "Ayamiss the Hunter"
				[723] = 6, -- "Ossirian the Unscarred"

			-- Temple of Ahn'Qiraj
				[709] = 1, -- "The Prophet Skeram"
				[710] = 2, -- "Silithid Royalty"
				[711] = 3, -- "Battleguard Sartura"
				[712] = 4, -- "Fankriss the Unyielding"
				[713] = 5, -- "Viscidus"
				[714] = 6, -- "Princess Huhuran"
				[715] = 7, -- "Twin Emperors"
				[716] = 8, -- "Ouro"
				[717] = 9, -- "C'thun"

			-- Blackrock Depths (WoW 20th Anniversary Update)
				[3042] = 1, -- Lord Roccor
				[3044] = 2, -- Bael'Gar
				[3043] = 3, -- Lord Incendius
				[3046] = 4, -- Golem Lord Argelmach
				[3048] = 5, -- The Seven
				[3045] = 6, -- General Angerforge
				[3047] = 7, -- Ambassador Flamelash
				[3049] = 8, -- Emperor Dagran Thaurissan

		-- TBC
			-- Karazhan
				--!!! Servant's Quarters (Rokad the Ravager, Shadikith the Glider, Hyakiss the Lurker)
				[652] = 2, -- "Attumen the Huntsman"
				[653] = 3, -- "Moroes"
				[654] = 4, -- "Maiden of Virtue"
				[655] = 5, -- "Opera Hall"
				[656] = 6, -- "The Curator"
				[657] = 7, -- "Terestian Illhoof"
				[658] = 8, -- "Shade of Aran"
				[659] = 9, -- "Netherspite"
				[660] = 10, -- "Chess Event"
				[661] = 11, -- "Prince Malchezaar"
				[662] = 12, -- "Nightbane"

			-- Gruul's Lair
				[649] = 1, -- "High King Maulgar"
				[650] = 2, -- "Gruul the Dragonkiller"

			-- Magtheridon's Lair
				[651] = 1, -- "Magtheridon"

			-- Serpentshrine Cavern
				[623] = 1, -- "Hydross the Unstable"
				[624] = 2, -- "The Lurker Below"
				[625] = 3, -- "Leotheras the Blind"
				[626] = 4, -- "Fathom-Lord Karathress"
				[627] = 5, -- "Morogrim Tidewalker"
				[628] = 6, -- "Lady Vashj"

			-- The Eye
				[730] = 1, -- "Al'ar"
				[731] = 2, -- "Void Reaver"
				[732] = 3, -- "High Astromancer Solarian"
				[733] = 4, -- "Kael'thas Sunstrider"

			-- The Battle for Mount Hyjal
				[618] = 1, -- "Rage Winterchill"
				[619] = 2, -- "Anetheron"
				[620] = 3, -- "Kaz'rogal"
				[621] = 4, -- "Azgalor"
				[622] = 5, -- "Archimonde"

			-- Black Temple
				[601] = 1, -- "High Warlord Naj'entus"
				[602] = 2, -- "Supremus",
				[603] = 3, -- "Shade of Akama"
				[604] = 4, -- "Teron Gorefiend",
				[605] = 5, -- "Gurtogg Bloodboil",
				[606] = 6, -- "Reliquary of Souls",
				[607] = 7, -- "Mother Shahraz",
				[608] = 8, -- "The Illidari Council",
				[609] = 9, -- "Illidan Stormrage",

			-- Sunwell Plateau
				[724] = 1, -- "Kalecgos"
				[725] = 2, -- "Brutallus"
				[726] = 3, -- "Felmyst"
				[727] = 4, -- "Eredar Twins"
				[728] = 5, -- "M'uru"
				[729] = 6, -- "Kil'jaeden"

		-- Wrath
			-- Vault of Archavon
				[1126] = 1, -- "Archavon the Stone Watcher"
				[1127] = 2, -- "Emalon the Storm Watcher"
				[1128] = 3, -- "Koralon the Flame Watcher"
				[1129] = 4, -- "Toravon the Ice Watcher"

			-- The Obsidian Sanctum
				[1093] = 1, -- "Vesperon"
				[1092] = 2, -- "Tenebron"
				[1091] = 3, -- "Shadron"
				[1090] = 4, -- "Sartharion"

			-- Naxxramas
				[1107] = 1, -- "Anub'Rekhan"
				[1110] = 2, -- "Grand Widow Faerlina"
				[1116] = 3, -- "Maexxna"
				[1117] = 4, -- "Noth the Plaguebringer"
				[1112] = 5, -- "Heigan the Unclean"
				[1115] = 6, -- "Loatheb"
				[1113] = 7, -- "Instructor Razuvious"
				[1109] = 8, -- "Gothik the Harvester"
				[1121] = 9, -- "The Four Horsemen"
				[1118] = 10, -- "Patchwerk"
				[1111] = 11, -- "Grobbulus"
				[1108] = 12, -- "Gluth"
				[1120] = 13, -- "Thaddius"
				[1119] = 14, -- "Sapphiron"
				[1114] = 15, -- "Kel'Thuzad"

			-- The Eye of Eternity
				[1094] = 1, -- "Malygos"

			-- Ulduar
				[1132] = 1, -- "Flame Leviathan"
				[1136] = 2, -- "Ignis the Furnace Master"
				[1139] = 3, -- "Razorscale"
				[1142] = 4, -- "XT-002 Deconstructor"
				[1140] = 5, -- "The Assembly of Iron"
				[1137] = 6, -- "Kologarn"
				[1131] = 7, -- "Auriaya"
				[1135] = 8, -- "Hodir"
				[1141] = 9, -- "Thorim"
				[1133] = 10, -- "Freya"
				[1138] = 11, -- "Mimiron"
				[1134] = 12, -- "General Vezax"
				[1143] = 13, -- "Yogg-Saron"
				[1130] = 14, -- "Algalon the Observer"

			-- Trial of the Crusader
				[1088] = 1, -- "Northrend Beasts"
				[1087] = 2, -- "Lord Jaraxxus"
				[1086] = 3, -- "Faction Champions"
				[1089] = 4, -- "Val'kyr Twins"
				[1085] = 5, -- "Anub'arak"

			-- Onyxia's Lair
				[1084] = 1, -- "Onyxia"

			-- Icecrown Citadel
				[1101] = 1, -- "Lord Marrowgar"
				[1100] = 2, -- "Lady Deathwhisper"
				[1099] = 3, -- "Icecrown Gunship Battle"
				[1096] = 4, -- "Deathbringer Saurfang"
				[1097] = 5, -- "Festergut"
				[1104] = 6, -- "Rotface"
				[1102] = 7, -- "Professor Putricide"
				[1095] = 8, -- "Blood Council"
				[1103] = 9, -- "Queen Lana'thel"
				[1098] = 10, -- "Valithria Dreamwalker"
				[1105] = 11, -- "Sindragosa"
				[1106] = 12, -- "The Lich King"

			-- The Ruby Sanctum
				[1147] = 1, -- "Baltharus the Warborn",
				[1149] = 2, -- "Saviana Ragefire",
				[1148] = 3, -- "General Zarithrian",
				[1150] = 4, -- "Halion",

		-- Cata
			-- Baradin Hold
				[1033] = 1, -- "Argaloth"
				[1250] = 2, -- "Occu'thar"
				[1332] = 3, -- "Alizabal"

			-- Blackwing Descent
				[1027] = 1, -- "Omnotron Defense System"
				[1024] = 2, -- "Magmaw"
				[1022] = 3, -- "Atramedes"
				[1023] = 4, -- "Chimaeron"
				[1025] = 5, -- "Maloriak"
				[1026] = 6, -- "Nefarian's End"

			-- Throne of the Four Winds
				[1035] = 1, -- "Conclave of Wind"
				[1034] = 2, -- "Al'Akir"

			-- The Bastion of Twilight
				[1030] = 1, -- "Halfus Wyrmbreaker"
				[1032] = 2, -- "Theralion and Valiona"
				[1028] = 3, -- "Ascendant Council"
				[1029] = 4, -- "Cho'gall"
				[1083] = 5, -- "Sinestra"

			-- Firelands
				[1197] = 1, -- "Beth'tilac"
				[1204] = 2, -- "Lord Rhyolith"
				[1206] = 3, -- "Alysrazor"
				[1205] = 4, -- "Shannox"
				[1200] = 5, -- "Baleroc"
				[1185] = 6, -- "Majordomo Staghelm"
				[1203] = 7, -- "Ragnaros"

			-- Dragon Soul
				[1292] = 1, -- "Morchok"
				[1294] = 2, -- "Warlord Zon'ozz"
				[1295] = 3, -- "Yor'sahj the Unsleeping"
				[1296] = 4, -- "Hagara"
				[1297] = 5, -- "Ultraxion"
				[1298] = 6, -- "Warmaster Blackhorn"
				[1291] = 7, -- "Spine of Deathwing"
				[1299] = 8, -- "Madness of Deathwing"

		-- MoP
			-- Mogu'shan Vaults
				[1395] = 1, -- "The Stone Guard"
				[1390] = 2, -- "Feng the Accursed"
				[1434] = 3, -- "Gara'jal the Spiritbinder"
				[1436] = 4, -- "The Spirit Kings"
				[1500] = 5, -- "Elegon"
				[1407] = 6, -- "Will of the Emperor"

			-- Heart of Fear
				[1507] = 1, -- "Imperial Vizier Zor'lok"
				[1504] = 2, -- "Blade Lord Ta'yak"
				[1463] = 3, -- "Garalon"
				[1498] = 4, -- "Wind Lord Mel'jarak"
				[1499] = 5, -- "Amber-Shaper Un'sok"
				[1501] = 6, -- "Grand Empress Shek'zeer"

			-- Terrace of Endless Spring
				[1409] = 1, -- "Protectors of the Endless"
				[1505] = 2, -- "Tsulong"
				[1506] = 3, -- "Lei Shi"
				[1431] = 4, -- "Sha of Fear"

			-- Throne of Thunder
				[1577] = 1, -- "Jin'rokh the Breaker"
				[1575] = 2, -- "Horridon"
				[1570] = 3, -- "Council of Elders"
				[1565] = 4, -- "Tortos"
				[1578] = 5, -- "Megaera"
				[1573] = 6, -- "Ji-Kun"
				[1572] = 7, -- "Durumu the Forgotten"
				[1574] = 8, -- "Primordius"
				[1576] = 9, -- "Dark Animus"
				[1559] = 10, -- "Iron Qon"
				[1560] = 11, -- "Twin Consorts"
				[1579] = 12, -- "Lei Shen"
				-- What is the difference here?
				[1580] = 13, -- "Ra-den"
				[1581] = 13, -- "Ra-den"

			-- Siege of Orgrimmar
				[1602] = 1, -- "Immerseus"
				[1598] = 2, -- "Fallen Protectors"
				[1624] = 3, -- "Norushen"
				[1604] = 4, -- "Sha of Pride"
				[1622] = 5, -- "Galakras"
				[1600] = 6, -- "Iron Juggernaut"
				[1606] = 7, -- "Kor'kron Dark Shaman"
				[1603] = 8, -- "General Nazgrim"
				[1595] = 9, -- "Malkorok"
				[1594] = 10, -- "Spoils of Pandaria"
				[1599] = 11, -- "Thok the Bloodthirsty"
				[1601] = 12, -- "Siegecrafter Blackfuse"
				[1593] = 13, -- "Paragons of the Klaxxi"
				[1623] = 14, -- "Garrosh Hellscream"

		-- WoD
			-- Highmaul
				[1721] = 1, -- "Kargath Bladefist"
				[1706] = 2, -- "The Butcher"
				[1722] = 3, -- "Tectus, The Living Mountain"
				[1720] = 4, -- "Brackenspore"
				[1719] = 5, -- "Twin Ogron"
				[1723] = 6, -- "Ko'ragh"
				[1705] = 7, -- "Imperator Mar'gok"

			-- Blackrock Foundry
				[1696] = 1, -- "Oregorger the Devourer"
				[1693] = 2, -- "Hans'gar & Franzok"
				[1694] = 3, -- "Beastlord Darmac"
				[1691] = 4, -- "Gruul"
				[1689] = 5, -- "Flamebender Ka'graz"
				[1692] = 6, -- "Operator Thogar"
				[1690] = 7, -- "Blast Furnace"
				[1713] = 8, -- "Kromog, Legend of the Mountain"
				[1695] = 9, -- "The Iron Maidens"
				[1704] = 10, -- "Blackhand"

			-- Hellfire Citadel
				[1778] = 1, -- "Hellfire Assault"
				[1785] = 2, -- "Iron Reaver"
				[1787] = 3, -- "Kormrok"
				[1798] = 4, -- "Hellfire High Council"
				[1786] = 5, -- "Kilrogg Deadeye"
				[1783] = 6, -- "Gorefiend"
				[1788] = 7, -- "Shadow-Lord Iskar"
				[1794] = 8, -- "Socrethar the Eternal"
				[1777] = 9, -- "Fel Lord Zakuun"
				[1800] = 10, -- "Xhul'horac"
				[1784] = 11, -- "Tyrant Velhari"
				[1795] = 12, -- "Mannoroth"
				[1799] = 13, -- "Archimonde"

		-- Legion
			-- The Emerald Nightmare
				[1853] = 1, -- "Nythendra"
				[1873] = 2, -- "Il'gynoth, The Heart of Corruption"
				[1876] = 3, -- "Elerethe Renferal"
				[1841] = 4, -- "Ursoc"
				[1854] = 5, -- "Dragons of Nightmare"
				[1877] = 6, -- "Cenarius"
				[1864] = 7, -- "Xavius"

			-- Trial of Valor
				[1958] = 1, -- "Odyn"
				[1962] = 2, -- "Guarm"
				[2008] = 3, -- "Helya"

			-- The Nighthold
				[1849] = 1, -- "Skorpyron"
				[1865] = 2, -- "Chronomatic Anomaly"
				[1867] = 3, -- "Trilliax"
				[1871] = 4, -- "Spellblade Aluriel"
				[1862] = 5, -- "Tichondrius"
				[1842] = 6, -- "Krosus"
				[1886] = 7, -- "High Botanist Tel'arn"
				[1863] = 8, -- "Star Augur Etraeus"
				[1872] = 9, -- "Grand Magistrix Elisande"
				[1866] = 10, -- "Gul'dan"

			-- Tomb of Sargeras
				[2032] = 1, -- "Goroth"
				[2048] = 2, -- "Demonic Inquisition"
				[2036] = 3, -- "Harjatan"
				[2050] = 4, -- "Sisters of the Moon"
				[2037] = 5, -- "Mistress Sassz'ine"
				[2054] = 6, -- "The Desolate Host"
				[2052] = 7, -- "Maiden of Vigilance"
				[2038] = 8, -- "Fallen Avatar"
				[2051] = 9, -- "Kil'jaeden"

			-- Antorus, the Burning Throne
				[2076] = 1, -- "Garothi Worldbreaker"
				[2074] = 2, -- "Felhounds of Sargeras"
				[2070] = 3, -- "Antoran High Command"
				[2064] = 4, -- "Portal Keeper Hasabel"
				[2075] = 5, -- "Eonar the Life-Binder" -- The Defense of Eonar
				[2082] = 6, -- "Imonar the Soulhunter"
				[2088] = 7, -- "Kin'garoth"
				[2069] = 8, -- "Varimathras"
				[2073] = 9, -- "The Coven of Shivarra"
				[2063] = 10, -- "Aggramar"
				[2092] = 11, -- "Argus the Unmaker"

		-- BfA
			-- Uldir
				[2144] = 1, -- "Taloc"
				[2141] = 2, -- "MOTHER"
				[2128] = 3, -- "Fetid Devourer"
				[2136] = 4, -- "Zek'voz, Herald of Nzoth"
				[2134] = 5, -- "Vectis"
				[2145] = 6, -- "Zul, Reborn"
				[2135] = 7, -- "Mythrax the Unraveler"
				[2122] = 8, -- "G'huun"

			-- Battle of Dazar'alor
				[2265] = 1, -- "Champion of the Light"
				[2285] = 2, -- "Jadefire Masters (A)"
				[2263] = 2, -- "Grong, the Jungle Lord (H)"
				[2284] = 3, -- "Grong, the Revenant (A)"
				[2266] = 3, -- "Jadefire Masters (H)"
				[2271] = 4, -- "Opulence"
				[2268] = 5, -- "Conclave of the Chosen"
				[2272] = 6, -- "King Rastakhan"
				[2276] = 7, -- "High Tinker Mekkatorque"
				[2280] = 8, -- "Stormwall Blockade"
				[2281] = 9, -- "Lady Jaina Proudmoore"

			-- Crucible of Storms
				[2269] = 1, -- "The Restless Cabal"
				[2273] = 2, -- "Uu'nat, Harbinger of the Void"

			-- The Eternal Palace
				[2298] = 1, -- Abyssal Commander Sivara
				[2289] = 2, -- Blackwater Behemoth
				[2305] = 3, -- Radiance of Azshara
				[2304] = 4, -- Lady Ashvane
				[2303] = 5, -- Orgozoa
				[2311] = 6, -- The Queen's Court
				[2293] = 7, -- Za'qul, Harbinger of Ny'alotha
				[2299] = 8, -- Queen Azshara

			-- Ny'alotha, the Waking City
				[2329] = 1, -- Wrathion, the Black Emperor
				[2327] = 2, -- Maut
				[2334] = 3, -- The Prophet Skitra
				[2328] = 4, -- Dark Inquisitor Xanesh
				[2333] = 5, -- The Hivemind
				[2335] = 6, -- Shad'har the Insatiable
				[2343] = 7, -- Drest'agath
				[2345] = 8, -- Il'gynoth, Corruption Reborn
				[2336] = 9, -- Vexiona
				[2331] = 10, -- Ra-den the Despoiled
				[2337] = 11, -- Carapace of N'Zoth
				[2344] = 12, -- N'Zoth the Corruptor

		-- SL
			-- Castle Nathria
				[2398] = 1, -- Shriekwing
				[2398] = 2, -- Huntsman Altimor
				[2398] = 3, -- Sun King's Salvation
				[2398] = 4, -- Artificer Xy'mox
				[2398] = 5, -- Hungering Destroyer
				[2398] = 6, -- Lady Inerva Darkvein
				[2398] = 7, -- The Council of Blood
				[2398] = 8, -- Sludgefist
				[2398] = 9, -- Stone Legion Generals
				[2398] = 10, -- Sire Denathrius

			-- Sanctum of Domination
				[2423] = 1, -- The Tarragrue
				[2423] = 2, -- The Eye of the Jailer
				[2423] = 3, -- The Nine
				[2423] = 4, -- Remnant of Ner'zhul
				[2423] = 5, -- Soulrender Dormazain
				[2423] = 6, -- Painsmith Raznal
				[2423] = 7, -- Guardian of the First Ones
				[2423] = 8, -- Fatescribe Roh-Kalo
				[2423] = 9, -- Kel'Thuzad
				[2423] = 10, -- Sylvanas Windrunner

			-- Sepulcher of the First Ones
				[2512] = 1, -- Vigilant Guardian
				[2512] = 2, -- Skolex, the Insatiable Ravener
				[2512] = 3, -- Artificer Xy'mox
				[2512] = 4, -- Dausegne, the Fallen Oracle
				[2512] = 5, -- Prototype Pantheon
				[2512] = 6, -- Lihuvim, Principal Architect
				[2512] = 7, -- Halondrus the Reclaimer
				[2512] = 8, -- Anduin Wrynn
				[2512] = 9, -- Lords of Dread
				[2512] = 10, -- Rygelon
				[2512] = 11, -- The Jailer

		-- DF
			-- Vault of the Incarnates
				[2587] = 1, -- Eranog
				[2639] = 2, -- Terros
				[2590] = 3, -- The Primal Council
				[2592] = 4, -- Sennarth, the Cold Breath
				[2635] = 5, -- Dathea, Ascended
				[2605] = 6, -- Kurog Grimtotem
				[2614] = 7, -- Broodkeeper Diurna
				[2607] = 8, -- Raszageth the Storm-Eater

			-- Aberrus, the Shadowed Crucible
				[2688] = 1, -- Kazzara, the Hellforged
				[2687] = 2, -- The Amalgamation Chamber
				[2693] = 3, -- The Forgotten Experiments
				[2682] = 4, -- Assault of the Zaqali
				[2680] = 5, -- Rashok, the Elder
				[2689] = 6, -- The Vigilant Steward, Zskarn
				[2683] = 7, -- Magmorax
				[2684] = 8, -- Echo of Neltharion
				[2685] = 9, -- Scalecommander Sarkareth

			-- Amirdrassil, the Dream's Hope
				[2820] = 1, -- Gnarlroot
				[2709] = 2, -- Igira the Cruel
				[2737] = 3, -- Volcoross
				[2728] = 4, -- Council of Dreams
				[2731] = 5, -- Larodar, Keeper of the Flame
				[2708] = 6, -- Nymue, Weaver of the Cycle
				[2824] = 7, -- Smolderon
				[2786] = 8, -- Tindral Sageswift, Seer of the Flame
				[2677] = 9, -- Fyrakk the Blazing

		-- TWW
			-- Nerub-ar Palace
				[2902] = 1, -- Ulgrax the Devourer
				[2917] = 2, -- The Bloodbound Horror
				[2898] = 3, -- Sikran, Captain of the Sureki
				[2918] = 4, -- Rasha'nan
				[2919] = 5, -- Broodtwister Ovi'nax
				[2920] = 6, -- Nexus-Princess Ky'veza
				[2921] = 7, -- The Silken Court
				[2922] = 8, -- Queen Ansurek 

	}
}
ns.orderTable = orderTable


--------------------------------------------------------------------------------
-- #EOF
--------------------------------------------------------------------------------