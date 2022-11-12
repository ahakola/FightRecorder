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

### FightRecorder data structures

FightRecorder uses `SavedVariables` to save variable data about the best pulls and progress to first kills and `RaidData.lua` to save hard coded constant data about different `instanceId`, `encounterId` and `creatureId` to differentiate, order and fix the data inside the `SavedVariables`.

You can read more about these from the [SavedVariables.md](/SavedVariables.md) and [RaidData.md](/RaidData.md)

---

**(c) 2014 - 2022**

**All rights reserved**, because this was for personal use only addon and I borrowed some bits of code from other addons with all rights reserved and I can't remember if those parts have been removed/rewritten during the years or there still are remnants of other peoples code with reserved rights left.

If I was 100% sure, I would use some other license, but for now, use this as a sort of specification for your own cleanroom implementation and let me know if you need more information.

---