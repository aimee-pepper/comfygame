// Stable records stay in the source layer; pages render only their player-facing labels.
export const apothecaryFirstUse = {
  stationID: 'apothecary',
  travellerID: 'nessa',
  recipeID: 'lesser-salve',
  resultID: 'salve_lesser',
  construction: '85 Essence · 16 Clay · 6 Quartz · 12 Reagent',
  firstRecipe: '1 flexible material at 25+ · 1 Resin · 0 Essence',
  journey: [
    'Recruit Nessa. Her accepted arrival makes the Apothecary foundation available in Home → Make.',
    'Open the Apothecary foundation, compare the complete four-part construction bundle, and build only when the displayed stock is sufficient.',
    'A completed build opens the tier-0 Apothecary and teaches Lesser Salve. It does not prepare or grant a Salve.',
    'On your first visit, select Lesser Salve and review the required flexible material and Resin. Prepare it once you have both ingredients.',
  ],
  shortfalls: [
    'No qualifying material and no Resin: Needs 1 flexible material at 25+ and 1 Resin.',
    'A qualifying material but no Resin: Needs 1 Resin.',
    'Resin but no qualifying material: Needs 1 flexible material at 25+.',
    'Both are present: Ready to prepare.',
  ],
  boundaries: [
    'Construction teaches Lesser Salve but spends no recipe material and creates no item.',
    'A successful preparation uses one qualifying material and 1 Resin, then places one Lesser Salve in the Storehouse or Waiting, depending on the space available.',
    'Cancelling, missing an ingredient, changed stock, another busy action, or a save failure leaves your materials and recipe knowledge unchanged. The recipe stays open so you can read what is missing.',
    'After reopening the game, an unfinished build remains unfinished. A completed build keeps the Apothecary and Lesser Salve knowledge, while a successful preparation keeps its one stored result.',
  ],
  inference: 'Bringing suggestive partial stock can reveal one additional current recipe without consuming stock or preparing an item. Its detail then names every remaining requirement. Partial stock never makes Lesser Salve—or another recipe—ready by itself.',
  catalogueBoundary: 'Building the room does not reveal Scent Mask, Stillwater, Waystone, coatings, cures, tools, or the full preparation catalogue. Writing ink and vial preparation remain at the Scriptorium.',
  costs: [
    'Ordinary preparations use 0 Essence under their own current recipes.',
    'Stillwater adds 6 Essence to its listed materials.',
    'Waystone adds 12 Essence and 1 Mote to its listed materials.',
  ],
};
