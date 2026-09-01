// Stable records stay in the source layer; pages render only their player-facing labels.
export const surveyPostFirstUse = {
  travellerID: 'mara',
  stationID: 'survey_post',
  researchBranchID: 'instruments',
  construction: '50 Essence · 10 Timber · 8 Iron Ore · 2 Quartz',
  journey: [
    'Recruit Mara to reveal one Survey Post foundation in Home → Study.',
    'Build only when the exact 50 Essence, 10 Timber, 8 Iron Ore, and 2 Quartz quote is ready.',
    'Construction opens the tier-0 Survey Post and Field Instruments research. It grants no instrument, material, observation, map disclosure, or field action.',
    'Study one current Field Instrument only from its exact Research preview. A durable purchase makes that subject a permanent Crude capability and packs it for the next world.',
    'At Home, choose the owned instruments for the next trip. Departure freezes that chosen set and its current precision for the expedition.',
    'In the world, use Survey only while no encounter is active. It reads every valid carried instrument in canonical order, records those observations, and costs one turn.',
  ],
  instruments: [
    ['sunglass', 'Sunglass', 'Illumination', '30 Essence · 3 Copper · 2 Quartz'],
    ['level', 'Level', 'Relief', '35 Essence · 2 Copper · 6 Timber'],
    ['thermoscope', 'Thermoscope', 'Thermal', '55 Essence · 2 Mercury · 3 Quartz'],
    ['hygrometer', 'Hygrometer', 'Hydrology', '55 Essence · 8 Fibre · 2 Silver'],
    ['loupe', 'Loupe', 'Substrate', '60 Essence · 4 Quartz · 2 Silver'],
    ['vivometer', 'Vivometer', 'Vitality', '90 Essence · 2 Ichor · 4 Quartz · 4 Resin'],
    ['barometer', 'Barometer', 'Atmosphere', '95 Essence · 3 Mercury · 3 Quartz · 3 Silver'],
    ['chronometer', 'Chronometer', 'Cycle', '150 Essence · 2 Adamant · 5 Quartz · 5 Silver'],
  ] as const,
  loadoutAndSurvey: [
    'An unconfigured next-trip loadout carries every owned instrument. The first change creates an explicit choice; an explicit empty loadout remains empty after relaunch.',
    'Instruments are permanent Reality capabilities, not Storehouse stacks, Field Kit supply entries, equipment, or output-bin objects. A full Storehouse or Waiting pile cannot block studying or improving one.',
    'The active World Field Kit tray is read-only: it shows only the exact subjects and precisions frozen at departure. Home changes cannot alter that expedition.',
    'Survey consumes no instrument and promises no coordinate, resource, site, traveller, fog reveal, or map completion. It records only the carried subjects and advances one ordinary turn.',
  ],
  refusalAndRelaunch: [
    'Before a durable construction or Research receipt, a shortfall, stale preview, unavailable Mara, busy action, or failed save spends nothing and keeps the current preview truthful.',
    'No packed valid instrument says so; an active encounter must finish first. A stale field state records neither an observation nor a turn.',
    'Mara being away changes only the current Home Research discount. It does not lock the station, remove ownership, or rewrite a completed cost.',
    'After relaunch, the station, completed Research, explicit Home loadout, frozen expedition instruments, and observations retain their durable truth without a duplicate grant, reading, or spend.',
  ],
  improvementBoundary: [
    'Current material thresholds describe a future exact-instrument improvement: Crude → Good needs two property-35+ Home materials and 20 Essence; Good → Fine needs three property-65+ materials and 50 Essence.',
    'The visible improvement surface does not yet own a typed quote, exact selected-material receipt, or exact refusal result. This guide therefore does not promise a paid improvement, consumed material, or precision success.',
    'When that bounded transaction lands, it must preserve the same permanent instrument identity and affect only future departures; it must never place a physical output in Storehouse or alter an active run.',
  ],
} as const;
