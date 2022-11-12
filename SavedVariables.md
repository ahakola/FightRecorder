## SavedVariables

Saved fight data for FightRecorder.

FightRecorder uses three different `SavedVariables` to save different types of data from recorded boss fights. This data is later used to compare between last and (previous) best pulls, keep track of the pull progress to your first boss kill and save useful instance and NPC names with matching Ids that are yet to be hard coded into `RaidData.lua` for later use.

You can use ingame command `/frec clear` to clean these `SavedVariables` from invalid saved data and previously saved temporary name and Id data that has been hard coded into `RaidData.lua` later.

### FightRecorderData

`FightRecorderData` or `dataDB` is used to save the HP data of the best pulls on different bosses and mobs alogn side with the basic information about the encounter itself.

Best pull is defined by either the fastest kill time or the best phase and/or lowest boss' HP on wipe if the boss is yet to be killed.

Saved data is arranged in nested tables primarily by `instanceId`, secondarily by `encounterId` and tertiary by `difficultyId`.

```lua
	dataDB = {
		[instanceId] = {
			[encounterId] = {
				[difficultyId] = {
					["info"] = table
					["name"] = table
					["data"] = table
				}
			}
		}
	}
```

---

Table `["info"]` contains basic information about the encounter (`instanceId`, `encounterId`, `encounterName`, `difficultyId`), information about the pull (`bestPhase`, `bestTry`, `timer`, `timestamp`, `endStatus`) and the raid (`playerName`, `raidSize`).

If the raid can't kill/finish the boss, the boss' remaining HP percent is stored in `bestTry` and `endStatus` is set to `0` to mark a wipe. On boss kill these two variables are set to `0` and `1` respectively.

**Example:** _Uldir_, _MOTHER Heroic_ is killed in the first room (in this fight room changes are counted as phases) with raidsize of 12 players in 159 seconds.

```lua
	["info"] = {
		["bestPhase"] = 1,
		["playerName"] = "Sanex",
		["raidSize"] = 12,
		["encounterID"] = 2141,
		["encounterName"] = "MOTHER",
		["difficultyID"] = 15,
		["instanceID"] = 1031,
		["timer"] = 159.020000000019,
		["timestamp"] = "2018.11.22 - 20:10:46",
		["bestTry"] = 0,
		["endStatus"] = 1,
	}
```

**N.B.:** The addon sets `bestTry` to `0` eventhough this fight ends when boss' HP reaches 10%. This is done because the snapshotting is getting different decimals for the boss' HP percent on every kill and to prevent cases where slower than the previous best could be falsely marked as new best due to RNG of getting lower HP percent decimals when the encounter ends.

---

Table `["name"]` is used to store the names of the different bosses and their adds in the fight.

```lua
	Table ["name"] (list of names of the bosses and adds present in this encounter)
		[creatureId] = "Name"
```

**Example:** _Uldir_, _MOTHER Mythic_ where different rooms get boss frames. They are marked in the `RaidData.lua` as boss adds so they don't count towards the HP percents and progress of the encounter in case of a wipe.

```lua
	["name"] = {
		[136429] = "Chamber 01",
		[137022] = "Chamber 02",
		[135452] = "MOTHER",
		[137023] = "Chamber 03",
	}
```

---

Table `["data"]` contains the different snapshots of the HP percents of different boss frames and wheter or not someone in the raid has Heroism/Bloodlust/Timewarp/Drums buff on.

On event `ENCOUNTER_START` the addon saves first snapshot on second `0` to the `["data"]` table and after this these snapshots are taken once a second. Every snapshot is a table containing table `["health"]` nested table for every different `creatureId`. Inside these `[creatureId]` tables are all the different mobs with the same `creatureId` separated by `spawnId` and their HP percents. Presence of Heroism-type buff in snapshots is marked with boolean `buff` that is set to `true`.

```lua
	Table ["data"] (snapshots taken once per second of the fight starting from second 0 on the pull)
		{
			Table ["health"] (table containing list of different creatureIds present in this snapshot)
				Table [creatureId] (list of different spawnIds with same creatureId)
					[spawnId] = HP (in percent)
			["buff"] = boolean
		}
```

**Example:** _Uldir_, _MOTHER Normal_ where the boss is killed in the first room. In this example you can see the the seconds `1-4`, `151` (last) and the `0`-second snapshots of the encounter with Heroism-type buff being marked for the snapshots of the seconds `3` and `4`.

```lua
	["data"] = {
		{
			["health"] = {
				[135452] = {
					["00001FEB7A"] = 100,
				},
				[136429] = {
					["00001FEE72"] = 100,
				},
			},
		}, -- [1]
		{
			["health"] = {
				[135452] = {
					["00001FEB7A"] = 99.8970795463067,
				},
				[136429] = {
					["00001FEE72"] = 100,
				},
			},
		}, -- [2]
		{
			["health"] = {
				[135452] = {
					["00001FEB7A"] = 99.6962295773235,
				},
				[136429] = {
					["00001FEE72"] = 100,
				},
			},
			["buff"] = true,
		}, -- [3]
		{
			["health"] = {
				[135452] = {
					["00001FEB7A"] = 99.3789665787288,
				},
				[136429] = {
					["00001FEE72"] = 100,
				},
			},
			["buff"] = true,
		}, -- [4]

		.
		.
		.

		{
			["health"] = {
				[135452] = {
					["00001FEB7A"] = 10.0866426906855,
				},
				[136429] = {
					["00001FEE72"] = 100,
				},
			},
		}, -- [151]
		[0] = {
			["health"] = {
				[135452] = {
					["00001FEB7A"] = 100,
				},
				[136429] = {
					["00001FEE72"] = 100,
				},
			},
		},
	}
```

### FightRecorderProgressData

`FightRecorderProgressData` or `progressDB` is used to save the progress on different encounters and difficulties from first pull to the first kill. From every wipe and the first kill the fight lenght and fight progress is saved. The addon also saves your roster per `instanceId` based on players who were present on the progress/kills.

Fight progress on the wipes contains data about the boss' HP percents and the phase the encounter ended. After the first kill this data isn't saved anymore, but the per `instanceId` roster is still being updated on later kill.

Saved data is arranged in nested tables primarily by `instanceId`, secondarily by `encounterId` and tertiary by `difficultyId`. Roster information is saved in`["roster"]` table located inside the `[instanceId]` table.

```lua
	progressDB = {
		[instanceId] = {
			[encounterId] = {
				[difficultyId] = table
			},
			["roster"] = {
				["PlayerName"] = table
			}
		}
	}
```

---

Table `[difficultyId]` contains nested table for every progress wipe and first kill with information about `combatTime`, `percent` and `phase` for that invidual pull. The lenght of the pull is saved in `combatTime` in seconds, the combined average percent of remaining bosses in `percent`, and the phase number where the encounter ended is saved in the `phase` variable.

```lua
	Table [difficultyId] (progress saved with each pull in invidual table)
		{
			["combatTime"] = time (in seconds),
			["percent"] = HP (in percent),
			["phase"] = phaseNumber,
		}
```

**Example:** _Battle of Dazar'alor_, _High Tinker Mekkatorque Normal_ with progress of two wipes before first kill.

```lua
	[14] = {
		{
			["combatTime"] = 400.670999999857,
			["percent"] = 40.285653010206,
			["phase"] = 2,
		}, -- [1]
		{
			["combatTime"] = 300.004999999888,
			["percent"] = 42.6410371707795,
			["phase"] = 1,
		}, -- [2]
		{
			["combatTime"] = 566.57200000016,
			["percent"] = 0,
			["phase"] = 2,
		}, -- [3]
	}
```

---

Table `["roster"]` contains table for every player who has been present during the progress and post-progress re-kills of the bosses for the same `instanceId` raids. In this table data is saved about `timestamp` of when the player was first and last seen in these raids and information about their guild including `guildName`, `guildRank`, `guildRankIndex` and `guildHistory` if the player has changed guilds during all the recorded raids in the same instance.

```lua
	Table ["PlayerName"] (Table containing information about the player in question)
		["firstSeen"] = timestamp,
		["lastSeen"] = timestamp,
		["guildName"] = "guildName",
		["guildRank"] = "guildRankName",
		["guildRankIndex"] = guildRankIndex,
		Table ["guildHistory"] (Table containing guild history in invidual tables)
			{
				timestamp,
				"OldGuildName",
				"NewGuildName"
			}
```

**Example:** Player ~~NameRedacted~~ who was previously un-guilded but joined the guild during the raid as a Social.

```lua
	["NameRedacted"] = {
		["guildRank"] = "Social",
		["guildRankIndex"] = 6,
		["lastSeen"] = "2019.12.15 - 21:41:12",
		["firstSeen"] = "2019.12.15 - 20:06:06",
		["guildHistory"] = {
			{
				"2019.12.15 - 20:18:41", -- [1]
				nil, -- [2]
				"Lords of Ironhearts", -- [3]
			}, -- [1]
		},
		["guildName"] = "Lords of Ironhearts",
	},
```

### FightRecorderBossData

`FightRecorderBossData` or `bossDB` contains saved information from encounters that should be hard coded into `RaidData.lua`, but isn't there yet. This includes previously unseen Ids and Names for instances, encounters and bosses and their adds.

```lua
	bossDB = {
		[instanceId] = {
			["name"] = "instanceName",
			[encounterId] = {
				["name"] = "encounterName",
				[creatureId] = "bossName",
			}
		}
	}
```

After these are added to `RaidData.lua`, you can use ingame command `/frec clear` to clean the newly hard coded data from `bossDB` to keep it more manageable.

---

**Example:** _Ny'alotha, the Waking City_ `instanceId`and `instanceName` with three new `encounterId` and `encounterName` and their related `creatureId` and `creatureName` information saved ready to be added to `RaidData.lua`.

```lua
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
	}

```

**N.B.:** Addon can't differentiate between all the different `creatureId` saved to the `bossDB` whether or not they are actual bosses. When saving the data to the `RaidData.lua`, make sure you add bosses and boss adds to right places or trivial adds might be counted towards your progress.