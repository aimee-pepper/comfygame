export const blacksmithFirstUse = {
  travellerID: 'halloway',
  stationID: 'blacksmith',
  schematicID: 'pointed_blade',
  construction: '20 Essence · 8 Iron · 4 Plant Fibre · 4 Logs',
  correctedRequest:
    'Iron enough for the work, fibre enough to bind the frame, and somewhere out of the wind.',
  journey: [
    'Recruit Halloway to reveal one Blacksmith foundation in Home → Make.',
    'Build when you have the displayed 20 Essence, 8 Iron, 4 Plant Fibre and 4 Logs.',
    'Construction opens the T1 Forge: Pointed Blade, Cutting Blade, Hand Maul and Shield. It grants no gear or free stock.',
    'Open Make and choose a known equipment recipe. Long Spear, Helm, Rigid Guard and same-item refitting open at T2; Halloway does not provide a free starter piece.',
    'Choose one suitable point and a different suitable grip, then review their quality, material effects, Essence cost, finished statistics, and Storehouse or Waiting destination.',
    'Confirm Make only while the preview still matches your chosen materials. A successful craft creates one physical piece and consumes only the selected ingredients and displayed cost.',
  ],
  pointedBlade: [
    'Pointed Blade is a Close Pierce weapon. It uses one suitable point and one different suitable grip.',
    'Choose 4 Iron plus 1 Coal, 2 Quartz, 1 Bone, or 2 Ingots at T2 for the point. The grip uses 1 Log plus 2 Plant Fibre, or a separate Bone grip. One unit cannot fill both components.',
    'Ordinary Forge crafting costs 0 Essence. Actual working parts determine Power or Protection; workmanship is separate. Coal is spent fuel.',
    'Choosing, resetting, or cancelling materials spends nothing. The finished piece goes to the Storehouse or Waiting destination shown in the preview.',
  ],
  stockBoundary:
    'Blacksmith Stock includes every suitable World or Creature Material kept at Home. A suitable Creature Material must appear in the available stock rather than being reported as zero.',
  reforgeBoundary: [
    'Select one identified piece from Storehouse, Waiting, or a person currently at Home. Gear still carried on an expedition is not recalled automatically.',
    'Selecting a piece does not move, unequip, merge, split, identify, or replace it. If its location, wearer, details, material history, or chosen ingredients change, reopen the preview.',
    'At T2, refit a chosen component bundle on that same owned piece. Review its complete replacement ingredients, changed statistics and displaced current parts before confirming; ordinary refit costs 0 Essence.',
    'Displaced current components return once. Spent Coal and historical constructions are not extra refunds. This does not promise a paid Reforge success or the unfinished Peerless refinement service.',
  ],
  refusalAndRelaunch: [
    'A physical-gear craft confirms success only after saving its result. If saving fails, the craft refuses without spending its ingredients or granting the item. The delivered Forge batch has focused and native verification; physical feature play acceptance remains separate.',
    'A saved physical-gear craft keeps its one result and payment together. A failed save leaves the craft unspent. Same-item refit is delivered; a separate Peerless refinement service remains unfinished.',
    'The game never substitutes another item with the same name. A completed Make or refit always applies to the one piece you selected.',
  ],
} as const;
