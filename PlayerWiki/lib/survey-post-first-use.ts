// Stable records stay in the source layer; pages render only their player-facing labels.
export const surveyPostFirstUse = {
  travellerID: 'mara',
  stationID: 'survey_post',
  researchBranchID: 'instruments',
  construction: '50 Essence · 10 Timber · 8 Iron Ore · 2 Quartz',
  journey: [
    'Recruit Mara to reveal one Survey Post foundation in Home → Study.',
    'Build when you have the displayed 50 Essence, 10 Timber, 8 Iron Ore, and 2 Quartz.',
    'Construction opens the tier-0 Survey Post and Field Instruments research. It grants no instrument, material, observation, map disclosure, or field action.',
    'Study one Field Instrument from its Research preview. A completed purchase permanently teaches that subject at Crude precision and makes it available for the next world.',
    'At Home, choose which learned instruments to take on the next trip. Departure keeps that set and its precision unchanged for the expedition.',
    'In the world, use Survey only while no encounter is active. It reads every valid carried instrument in a consistent order, records the observations, and costs one turn.',
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
    'In a world, the Field Kit shows only the subjects and precision chosen at departure. Changes made at Home apply to a later expedition, not the current one.',
    'Survey consumes no instrument and promises no coordinate, resource, site, traveller, fog reveal, or map completion. It records only the carried subjects and advances one ordinary turn.',
  ],
  refusalAndRelaunch: [
    'If something is missing, the preview changes, Mara is unavailable, another action is busy, or the game cannot save, nothing is spent.',
    'If no usable instrument is packed, the game says so; an active encounter must finish first. If the world changes before Survey completes, it records no observation and spends no turn.',
    'When Mara is away, only her Home Research discount changes. The station and learned instruments remain available, and completed purchases keep their original price.',
    'After reopening the game, the station, completed Research, chosen Home loadout, expedition instruments, and observations return as saved without duplicating a purchase or reading.',
  ],
  improvementBoundary: [
    'Crude → Good is playable now and needs two property-35+ Home materials and 20 Essence; Good → Fine needs three property-65+ materials and 50 Essence.',
    'An improvement automatically chooses the weakest suitable materials kept at Home. The preview shows the Essence, materials, and resulting precision before you confirm.',
    'The improvement raises the same permanent instrument and affects only future departures; it never creates an item in Storehouse or alters an expedition already underway.',
  ],
} as const;
