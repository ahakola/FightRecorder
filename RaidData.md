## RaidData

RaidData Ids for FightRecorder.

`RaidData.lua` should containt every raid encounter and most of the `npcIds` of the bosses and adds. Data has been collected mostly using this addon, because that way I can make sure I only list the bosses and adds that actually have boss frames and they all have the right `npcIds` (Sometimes npcs with exact same name can have multiple different `npcIds` and not all of them are related to the encounter).

Data should cover all the raids from _Classic_ all the way to the end of the _BfA_, when I stopped playing Retail side of WoW. Data misses some of the Mythic difficulty `npcIds` because I didn't have access to all the fights when they were relevant and it is hard to catch them all alone later.

### recordThis

difficultyIds to record

```lua
	[difficultyId] = boolean
```

Set boolean `true` to record `difficultyId`, `false` to skip recording.
Use `/frec list` ingame to generate this list.

### instanceIDFixes

Fixing incorrect `instaceIds`. In old content (_Classic_ and _TBC_) sometimes encounters are marked under wrong `instanceId` when moving from one area to another (for example _AQ40_ going under ground after first boss or _Nigthbane_ in the balcony of _Karazhan_) and this table should provide the right `instanceId` when saving data to the DBs.

```lua
	Table [instanceId] (list of encounters in this wrong [instanceId])
		[encounterId] = instanceId
```

List of `encounterIds` with their right `instanceIds` inside the table named after the wrong `instanceId`.

> You find these in the `bossDB` if the encounters go under different `instanceIds` when you know they are inside the same raid.

### councilStyleEncounters

These ecnounters are _council style_ -encounters where you fight multiple bosses at the same time and you can choose the kill order yourself. In these fights the actual phases are replaced by number of bosses remaining.

In some cases these might not be an actually fight multiple bosses, but you kill the same boss again and again between different phases. DBM handles (at least some of) these fights as _coucil style_ and counts how many times you have left to "kill" the boss before the actual final kill.

**!!! NOTICE !!!**
I have only tested the the _BfA_ -encounters, for them actualy working I'm just guessing these others works as well...

```lua
	[encounterId] = "Encounter Name"
```

List of `encounterIds` with their matching encounter names.

### ignorePhasesEncounters

These ecnounters are alternating between different phases (like ground-phase and air-phase) until boss dies or you reach the last phase. Because sometimes these phases gets numbers (1, 2, ...) and you might get lower wipe than previous best, but the phase number is smaller, it wouldn't be recorded as a new record. With `encounterIds` in this table we can ignore the phases and focus solely on the boss' HP.

**!!! NOTICE !!!**
I have only tested the the _Ny'alotha_ -encounters, for them actualy working I'm just guessing these others works as well...

```lua
	[encounterId] = "Encounter Name"
```

List of `encounterIds` with their matching encounter names.

### ignoredNames

In some ecnounters players might get renamed and you might want to ignore those names in the guild check.

```lua
	["Name"] = true
```

List of names to be ignored in guild check.

### RaidEncounterIDs

These ecnounters we know the `creatureIds` of the bosses and we can include `RaidBosses` instead of excluding `BossAdds` or guessing what to do.

> To keep the data somewhat organized, these are placed under tables named after abbreviations of their respective origin expansions.

```lua
	Table [instanceId] (list of encounters of instance [instanceId])
		[encounterId] = "Encounter Name"
```

List of `encounterIds` with their matching encounter names inside the table named after the `instanceId`.

### BossAdds

These get boss frame but ain't the real bosses or interesting adds or needs to be excluded from the graphs for any other reason.

> To keep the data somewhat organized, these are placed under tables named after abbreviations of their respective origin expansions.

```lua
	[creatureId] = "Additional Monster Name"
```

List of unique boss adds `creatureIds` with matching names.

### RaidBosses

These are the bosses or major adds we are interested in.

> To keep the data somewhat organized, these are placed under tables named after abbreviations of their respective origin expansions.

```lua
	[creatureId] = "Boss Name"
```

List of unique `creatureIds` of the boss monsters with matching names.

### orderTable

Sort the list of recorded encounters in instances on the left side of the Frame according to this priority list.

When adding new expansion packs, add number `1` to the front of all `ORDER` numbers in table `r` (lazy way) and make new separator with `instanceId` key-value set to higher than previous expansion packs corresponding separator.

```lua
	Table ["r"] (list of Raid Instances)
		[instanceId] = ORDER
```

Sort `instanceIds` based on `ORDER`.

```lua
	Table ["e"] (list of Raid Encounters)
		[encounterId] = ORDER
```

Sort `encounterIds` inside their own `instanceIds` based on `ORDER`.
