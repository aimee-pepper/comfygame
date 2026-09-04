export const blacksmithFirstUse = {
  travellerID: 'halloway',
  stationID: 'blacksmith',
  schematicID: 'pointed_blade',
  construction: '30 Essence · 12 Iron Ore · 6 Fibre',
  correctedRequest:
    'Iron enough for the work, fibre enough to bind the frame, and somewhere out of the wind.',
  journey: [
    'Recruit Halloway to reveal one Blacksmith foundation in Home → Make.',
    'Build when you have the displayed 30 Essence, 12 Iron Ore, and 6 Fibre.',
    'Construction opens tier-0 Blacksmith and teaches Pointed Blade. It grants no gear, stock, salvage, reforge, or equipment change.',
    'Open Make and choose Pointed Blade. Reforge stays empty when you have no suitable gear at Home; Halloway does not provide a free starter piece.',
    'Choose one suitable point and a different suitable grip, then review their quality, material effects, Essence cost, finished statistics, and Storehouse or Waiting destination.',
    'Confirm Make only while the preview still matches your chosen materials. A successful craft creates one physical piece and consumes only the selected ingredients and displayed cost.',
  ],
  pointedBlade: [
    'Pointed Blade is a Close Pierce weapon. It uses one suitable point and one different suitable grip.',
    'A point may be an eligible mineral or creature hard-point unit; a grip may be an eligible fibre, timber, metal, or creature grip unit. One unit cannot fill both sockets.',
    'Quality sets the Essence cost: 12, 24, 48, or 80 Essence for quality tiers 1, 2, 3, or 4–5 before Halloway’s current discount.',
    'Choosing, resetting, or cancelling materials spends nothing. The finished piece goes to the Storehouse or Waiting destination shown in the preview.',
  ],
  stockBoundary:
    'Blacksmith Stock includes every suitable World or Creature Material kept at Home. A suitable Creature Material must appear in the available stock rather than being reported as zero.',
  reforgeBoundary: [
    'Select one identified piece from Storehouse, Waiting, or a person currently at Home. Gear still carried on an expedition is not recalled automatically.',
    'Selecting a piece does not move, unequip, merge, split, identify, or replace it. If its location, wearer, details, material history, or chosen ingredients change, reopen the preview.',
    'Reforge remains Planned until one preview can show the complete result: two materials with the required 30+ property, 8 Essence, the real combat-stat change, and the same piece, location, quality, family, and construction history.',
    'Until that corrected quote is available, this guide does not promise a paid Reforge success or repeat-rank improvement. It never treats Reforge as generic item upgrading.',
  ],
  refusalAndRelaunch: [
    'A physical-gear craft confirms success only after saving its result. If saving fails, the craft refuses without spending its ingredients or granting the item. This delivered correction has focused test coverage; an interactive crafting playthrough remains pending.',
    'A saved physical-gear craft keeps its one result and payment together. A failed save leaves the craft unspent. The future Reforge journey remains planned; this correction does not make Reforge available.',
    'The game never substitutes another item with the same name. A completed Make or future Reforge always applies to the one piece you selected.',
  ],
} as const;
