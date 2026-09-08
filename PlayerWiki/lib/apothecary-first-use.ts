// Stable records stay in the source layer; pages render only their player-facing labels.
export const apothecaryFirstUse = {
  stationID: 'apothecary',
  travellerID: 'nessa',
  recipeID: 'lesser-salve',
  resultID: 'salve_lesser',
  construction: '20 Essence · 4 Clay · 4 Logs',
  firstRecipe: '1 Plant Fibre · 1 Resin · 0 Essence',
  journey: [
    'Recruit Nessa. Her accepted arrival makes the Apothecary foundation available in Home → Make.',
    'Open the Apothecary foundation, compare the complete construction bundle, and build only when the displayed stock is sufficient.',
    'A completed build opens the Apothecary and teaches Lesser Salve. It does not prepare or grant a Salve.',
    'On your first visit, select Lesser Salve and review the required Plant Fibre and Resin. Prepare it once you have both ingredients.',
  ],
  shortfalls: [
    'No Plant Fibre and no Resin: Needs 1 Plant Fibre and 1 Resin.',
    'A Plant Fibre but no Resin: Needs 1 Resin.',
    'Resin but no Plant Fibre: Needs 1 Plant Fibre.',
    'Both are present: Ready to prepare.',
  ],
  boundaries: [
    'Construction teaches Lesser Salve but spends no recipe material and creates no item.',
    'A successful preparation uses 1 Plant Fibre and 1 Resin, then places one Lesser Salve in the Storehouse or Waiting, depending on the space available.',
    'Ordinary preparations confirm success only after saving. If saving fails, the preparation refuses without spending ingredients or granting the item. The complete delivered Apothecary has focused and native evidence; physical feature play acceptance remains separate.',
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
