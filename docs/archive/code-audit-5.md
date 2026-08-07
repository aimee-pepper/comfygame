# Code Audit #5 (2026-08-05, commit `043e645`)

401 tests, up from 343. **Everything flagged in audit #4 is fixed.** Generation is now genuinely end-to-end.

---

## 1. Fixed

| Audit #4 finding | Status |
|---|---|
| `LifeRules` built but never called | ✅ `Worldgen` draws the cast, rolls per-spawn jitter, keeps it on the foe |
| Armament collapsed to one scalar | ✅ **Triangle restored** — `pierce · crush · rend` with `.dominant` and `.isUnarmed` |
| Covering collapsed to two axes | ✅ `covering.hardness` and `covering.length` both present; `finish.schiller` too |
| No loot from traits | ✅ **`ButcheryRules`** — covering yields plate/shell/pelt by hardness, length and schiller; armament yields by dominant corner |
| Combat ignored traits | ✅ Foe armour and damage now read traits; `CreatureIdentity.tier` derives difficulty |
| Naming | ✅ Names say what sets a creature apart **from its own cast**, as specced |

**The chain now runs:** sigils → pressures → cast → spawned animal → combat → butchery → materials named after what they came from. That's the spine working.

---

## 2. The gap now: the player's half of combat is flat

Foes have trait-derived stats, armour, damage character and tier. **The player has almost none of that.**

- `binderAttack` is a **Tuning constant**. `companionAttack` barely more.
- **Gear has no damage type.** Grep for `pierce`/`crush`/`rend` in `Inventory` and `ContentModels`: nothing. Foes have a weapon triangle; the player's weapons don't.
- Four actions — attack, skill, item, flee — with one skill on a cooldown.
- **No crafting or recipes exist at all** (`Data/` has no recipe file), so the material chain ends at "you have materials."

So a fight is: tap attack until one side falls, occasionally tap skill. Foe variety is now real and the player has no way to respond to it — a heavily armoured bulwark and a fast fragile drifter are fought identically.

**This is the thing you do most often, and it's the thinnest system in the game.**

---

## 3. Also still unbuilt

- **Flora** — spec handed over; `growth` still has no producer.
- **Living worlds / predation** — spec handed over.
- **Anchoring's three routes**, named places, companions, the crystal currency, crafting buildings.

---

## 4. Priority

1. **Combat depth** — see `combat-depth-spec.md`. It's what makes generated variety *matter*.
2. **Flora** — unblocks cover, and cover is half of what makes creature traits tactically relevant.
3. **Crafting** — the material chain currently dead-ends.
4. Predation, anchoring, companions.
