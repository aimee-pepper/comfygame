export type WorldWritingRecipe = {
  id: string;
  stage: string;
  title: string;
  availability: string;
  composition: string[];
  pursuit: string;
  preparation: string;
  uncertainty: string;
  links: Array<{ label: string; href: string }>;
};

// IDs are retained for stable source ownership. Player-facing copy deliberately uses only
// the authored Page names and readable Writing vocabulary.
export const worldWritingRecipes: WorldWritingRecipe[] = [
  {
    id: 'starter_stone_hollow',
    stage: 'Early pursuit · opening stock',
    title: 'Stone Hollow',
    availability: 'One of the three already-inscribed World Pages available at the beginning of a campaign. It is read-only; writing the same request yourself uses the ordinary live Bind cost.',
    composition: ['Caverns', 'Ore'],
    pursuit: 'A practical early attempt at Iron Ore for the first Village workshops. Iron Ore may form on Stone or Rubble and needs no extraction tool.',
    preparation: 'The existing Page shows its live 16-Essence departure preview. Bring carrying room for the construction stock you actually mean to keep.',
    uncertainty: 'Stone and ordinary ore are more likely here; the Page does not promise a deposit, route, map shape, or enough Iron for every building.',
    links: [
      { label: 'Iron Ore', href: '/resources/ore' },
      { label: 'Blacksmith', href: '/buildings/blacksmith' },
      { label: 'Survey Post', href: '/buildings/survey-post' },
      { label: 'Reliquary', href: '/buildings/reliquary' },
    ],
  },
  {
    id: 'wild_gilded_caverns',
    stage: 'Middle pursuit · specialist seams',
    title: 'Gilded Caverns',
    availability: 'After two resolved expeditions, this repeatable World Page may enter the current ordinary page pool. It is usable only once you actually hold the Page; it is not a granted route.',
    composition: ['Caverns', 'Gilded Veins'],
    pursuit: 'A mid-reach attempt at valuable metal-bearing stone. Gold and Silver are the main hopes; Copper and Iron can still make the trip useful.',
    preparation: 'Its current Page preview is 19 Essence. Extraction 2 can work Gold and Silver seams if the world forms them. You may bind below that rank, but the Writing Desk warns about the shortfall before departure.',
    uncertainty: 'Rich seams are possible, not promised. A world can yield another useful metal—or none of the seam you wanted—and every mineral still needs a reachable Stone or Rubble host.',
    links: [
      { label: 'Gold', href: '/resources/gold' },
      { label: 'Silver', href: '/resources/silver' },
      { label: 'Copper', href: '/resources/copper' },
      { label: 'Weaponsmith', href: '/buildings/weaponsmith' },
      { label: 'Armoury', href: '/buildings/armoury' },
    ],
  },
  {
    id: 'world_recipe_high_vent_v1',
    stage: 'Late pursuit · player-written request',
    title: 'High Vent',
    availability: 'Not available until you own the Fountain pen and know Gold, Chasm, and Magma. This is a player-written composition, not an owned World Page or automatic Template.',
    composition: ['Overwhelming, countless Granite on Substrate', 'Moderate Gold on Substrate', 'Moderate Chasm on Relief', 'Great Magma on Thermal'],
    pursuit: 'A late mineral request that makes the conditions for Rift-glass, Mercury, and Adamant more plausible, with Gold and Silver as possible fallback value.',
    preparation: 'Use the live Bind cost and any selected anchoring premium. Extraction 3 can work Rift-glass and Mercury if found; Extraction 4 is needed for the full Adamant pursuit.',
    uncertainty: 'Several conditions remain unwritten. Rare seams still need the right reachable Stone, Rubble, Ash, height, or Chasm margin; this Page never guarantees a deposit, safe approach, or route.',
    links: [
      { label: 'Rift-glass', href: '/resources/rift-glass' },
      { label: 'Mercury', href: '/resources/mercury' },
      { label: 'Adamant', href: '/resources/adamant' },
      { label: 'World conditions', href: '/world' },
      { label: 'Research', href: '/research' },
    ],
  },
];
