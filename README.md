# Fight Recorder

This should show graphs about your progress when killing raid bosses HP- and timewise and also keep track and show your progress towards the first kill.

Crappy code, hacky features added on top of already hackier features and probably breaking something in the process...

...or at least everything will fall apart when I remove some old "unused" code or features.


#### FEATURE CREEP LIST AKA TODO:

- **Compression of dataDB for encounters?**

	This would only reduce the size of `SavedVariables` and nothing else would be really gained from this.

- **Something mind to the endless local-scoping**

	No need to local-scope every function we call, start with the functions used by the snapshotting and extend to the most used ones after that.

- **Remove all old unused and commented out code**

	You are not going to use it anymore, why save it and make this file longer than is needs to be? Some of it has been already removed, but there is still ton of stuff.

---


### Pictures

![BfA BoD - Lady Jaina Proudmoore HC - Graph of the fastest kill](/Pictures/BfA-BoD-LadyJainaProudmoore-DataGraph-HC.jpg?raw=true "BfA BoD - Lady Jaina Proudmoore HC - Graph of the fastest kill")

BfA BoD - Lady Jaina Proudmoore HC - Graph of the fastest kill

![BfA BoD - Lady Jaina Proudmoore HC - Graph of the progress to the first kill](/Pictures/BfA-BoD-LadyJainaProudmoore-ProgressGraph-HC.jpg?raw=true "BfA BoD - Lady Jaina Proudmoore HC - Graph of the progress to the first kill")

BfA BoD - Lady Jaina Proudmoore HC - Graph of the progress to the first kill

![Legion ToS - Goroth - Simulated graph of new fastest kill with the previous best (darker line)](/Pictures/Legion-ToS-Goroth-RecordSimulation-N&HC.jpg?raw=true "Legion ToS - Goroth - Simulated graph of new fastest kill with the previous best (darker line)")

Legion ToS - Goroth - Simulated graph of new fastest kill with the previous best (darker line)

---


### FightRecorder data structures

FightRecorder uses `SavedVariables` to save variable data about the best pulls and progress to first kills and `RaidData.lua` to save hard coded constant data about different `instanceId`, `encounterId` and `creatureId` to differentiate, order and fix the data inside the `SavedVariables`.

You can read more about these from the [SavedVariables.md](/SavedVariables.md) and [RaidData.md](/RaidData.md)

`/frec clear` cleans your `SavedVariables` from hard coded, misplaced, invalid or obsolete data.

`/frec populate` checks for new data from _Encounter Journal_ and your own `bossDB` ready to be exported and hard coded into `RaidData.lua`.

If you want to contribute your own collected data to the `RaidData.lua`, you can do it here at GitHub by either opening new _Issue_ or new _Pull Request_. If you open a new _Issue_, please use code tags by selecting your copy&pasted export and either press **Ctrl+E** or press the _Add Code_ -button for better readability.

---


### FightRecorderLite

FightRecorderLite is minimal version of the addon used to collect and export instanceIds, instanceNames, encounterIds, encounterNames, creatureIds and creatureNames during raid encounter just like the full version of the addon, but without the collection of all the HP, progress and timer data.

To run the FightRecorderLite you need to place `FightRecorderLite.toc`, `FightRecorderLite.lua` and `RaidData.lua` inside `Interface\Addons\FightRecorderLite` -folder.

`/frec` auto purges and exports the data from your own `bossDB` and also checks and exports new _Encounter Journal_ data to be hard coded into `RaidData.lua`.


---


**(c) 2014 - 2024**

**All rights reserved**, because this was for personal use only addon and I borrowed some bits of code from other addons with all rights reserved and I can't remember if those parts have been removed/rewritten during the years or there still are remnants of other peoples code with reserved rights left.

If I was 100% sure, I would use some other license, but for now, use this as a sort of specification for your own cleanroom implementation and let me know if you need more information.

---