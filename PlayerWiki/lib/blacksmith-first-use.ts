export const blacksmithFirstUse = {
  travellerID: 'halloway',
  stationID: 'blacksmith',
  schematicID: 'pointed_blade',
  construction: '30 Essence · 12 Iron Ore · 6 Fibre',
  correctedRequest:
    'Iron enough for the work, fibre enough to bind the frame, and somewhere out of the wind.',
  journey: [
    'Recruit Halloway to reveal one Blacksmith foundation in Home → Make.',
    'Build only when the exact 30 Essence, 12 Iron Ore, and 6 Fibre quote is ready.',
    'Construction opens tier-0 Blacksmith and teaches Pointed Blade. It grants no gear, stock, salvage, reforge, or equipment change.',
    'Open Make for the current Pointed Blade family. Reforge stays visibly empty when no eligible Home-owned physical gear exists; Halloway does not provide a starter piece.',
    'Choose one exact point and one different exact grip, then review their current quality, material effects, Essence cost, expected physical output, and Storehouse or Waiting destination.',
    'Confirm Make only when the retained quote still matches. The first durable receipt creates one exact physical piece and consumes only the selected inputs and current cost.',
  ],
  pointedBlade: [
    'Pointed Blade is a Close Pierce weapon. The current family uses one exact point and one different exact grip.',
    'A point may be an eligible mineral or creature hard-point unit; a grip may be an eligible fibre, timber, metal, or creature grip unit. One unit cannot fill both sockets.',
    'The current quality quote sets the Essence cost: 12, 24, 48, or 80 Essence for quality tiers 1, 2, 3, or 4–5 before the current keeper discount.',
    'Choosing, resetting, cancelling, or refusing a material suggestion spends nothing. The finished piece goes only to its quoted Storehouse or Waiting destination.',
  ],
  stockBoundary:
    'Blacksmith Stock counts every exact Home World or Creature Material the maker and reforge evaluators can select. A ready Creature Material quote is never treated as Stock 0.',
  reforgeBoundary: [
    'Select one identified physical piece only from Storehouse, Waiting, or a current human wearer at Home. Gear still carried in an expedition is not silently recalled.',
    'Selection does not move, unequip, merge, split, identify, or replace that exact piece. A stale location, owner, snapshot, receipt, or selected material requires a fresh quote.',
    'The useful one-step Reforge result is published only when its typed atomic quote is live: two exact property-30+ materials and 8 Essence, one real current-to-result combat change, and the same stable piece, location, quality, family, and construction history.',
    'Until that corrected quote is available, this guide does not promise a paid Reforge success or repeat-rank improvement. It never treats Reforge as generic item upgrading.',
  ],
  refusalAndRelaunch: [
    'A shortfall, changed foundation, unavailable Halloway, stale quote, busy control, or failed durable write leaves the current stock and visible preview unchanged; no success is shown.',
    'Relaunch before a durable build, Make, or Reforge restores the prior holdings and selected target. Relaunch after a durable receipt restores one completed result without a second spend, blade, or gear change.',
    'Same-name gear is never substituted. A completed Make or later corrected Reforge is one exact-instance receipt, not a generic reward or inferred salvage.',
  ],
} as const;
