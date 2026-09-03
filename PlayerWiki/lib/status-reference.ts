export type StatusReference = {
  id: string;
  slug: string;
  name: string;
  category: 'Encounter affliction' | 'World effect' | 'Encounter protection';
  summary: string;
  sources: string;
  effect: string;
  duration: string;
  boundary: string;
  clearing: string;
  persistence: string;
  itemSlugs: string[];
};

// This is a player-facing projection of the mounted combat and World rules.  It deliberately
// keeps encounter afflictions separate from the active-world effects that use similar words.
export const statusReferences: StatusReference[] = [
  {
    id: 'affliction-burn', slug: 'burn', name: 'Burn', category: 'Encounter affliction',
    summary: 'A short, hard damage-over-time affliction.',
    sources: 'A Heat emanation or a current burning weapon treatment can apply it.',
    effect: 'The current default is 4 damage for 2 ticks; an exact source can show a different strength or duration.',
    duration: 'Read the remaining ticks on the affected combatant.',
    boundary: 'Burn is an encounter affliction. It is not the same thing as a world hazard or a Field Kit effect.',
    clearing: 'Quenching Draught, Broad Antidote, or Quench can clear the applicable displayed affliction. Stonebark can turn aside the next eligible affliction before it lands.',
    persistence: 'It belongs to the current encounter only; it is not a lasting world-state effect.',
    itemSlugs: ['draught-quenching', 'antidote-broad', 'stonebark-tonic', 'firebrand'],
  },
  {
    id: 'affliction-poison', slug: 'poison', name: 'Poison', category: 'Encounter affliction',
    summary: 'A slower damage-over-time affliction that bypasses the normal armour question.',
    sources: 'A Caustic emanation, toxic combat source, or a current poison weapon treatment can apply it.',
    effect: 'The current default is 2 damage for 4 ticks; an exact source can show a different strength or duration.',
    duration: 'Read the remaining ticks on the affected combatant.',
    boundary: 'Combat Poison is distinct from poison left by chemical flora in the world.',
    clearing: 'Draught of Clearing, Broad Antidote, or Quench can clear the applicable displayed affliction. Stonebark can turn aside the next eligible affliction before it lands.',
    persistence: 'It belongs to the current encounter only. It does not convert into the separate flora-poison world effect.',
    itemSlugs: ['draught-clearing', 'antidote-broad', 'stonebark-tonic', 'venom'],
  },
  {
    id: 'affliction-dazzle', slug: 'dazzle', name: 'Dazzle', category: 'Encounter affliction',
    summary: 'An accuracy affliction rather than a damage-over-time wound.',
    sources: 'A Light emanation or a current dazzling weapon treatment can apply it.',
    effect: 'The current default deals no tick damage and gives a dazzled direct strike a 35% chance to miss for 2 ticks.',
    duration: 'Read the remaining ticks on the affected combatant.',
    boundary: 'Dazzle is an encounter affliction; it does not describe ordinary low visibility in a world.',
    clearing: 'Quenching Draught, Broad Antidote, or Quench can clear the applicable displayed affliction. Stonebark can turn aside the next eligible affliction before it lands.',
    persistence: 'It belongs to the current encounter only.',
    itemSlugs: ['draught-quenching', 'antidote-broad', 'stonebark-tonic', 'flashsalt'],
  },
  {
    id: 'affliction-bleed', slug: 'bleed', name: 'Bleed', category: 'Encounter affliction',
    summary: 'A wound that continues costing health during the encounter.',
    sources: 'A bleeding weapon treatment or a named attack can apply it.',
    effect: 'The current default is 2 damage for 3 ticks. Some exact sources can show a stronger or longer wound.',
    duration: 'Read the remaining ticks on the affected combatant.',
    boundary: 'Bleed is an encounter affliction, not the same thing as immediate contact damage in the world.',
    clearing: 'Draught of Clearing or Broad Antidote can clear the applicable displayed affliction. Quench does not clear Bleed.',
    persistence: 'It belongs to the current encounter only.',
    itemSlugs: ['draught-clearing', 'antidote-broad', 'briar-oil'],
  },
  {
    id: 'world-flora-poison', slug: 'flora-poison', name: 'Flora poison', category: 'World effect',
    summary: 'The lingering cost of stepping into a chemical plant profile.',
    sources: 'A disclosed chemical-flora contact can deal immediate harm and leave this world effect.',
    effect: 'It deals its shown world-turn poison damage while turns remain. Entering the same kind of danger renews the remaining time rather than stacking a second copy.',
    duration: 'It counts down on world turns in the active expedition.',
    boundary: 'This is not the encounter Poison affliction. Combat remedies are not presented as a field use.',
    clearing: 'The Field Kit does not currently offer a separate action that clears this world effect.',
    persistence: 'It is held in the active expedition state while its turns remain; completing or leaving a combat encounter does not make it a combat affliction.',
    itemSlugs: [],
  },
  {
    id: 'world-scent-mask', slug: 'scent-mask', name: 'Scent Mask', category: 'World effect',
    summary: 'A timed field effect that changes only scent-based creature notice.',
    sources: 'Apply a carried Scent Mask from the Field Kit outside combat.',
    effect: 'Animals relying only on scent hesitate for one action. Other senses and close contact still detect the party; it does not hide creatures or affect apexes.',
    duration: 'The current prepared mask lasts 12 world turns, with remaining turns shown in the Field Kit.',
    boundary: 'Scent Mask is a field effect, not an encounter affliction or a general stealth state.',
    clearing: 'It has no cure action; it ends when its displayed world-turn duration expires.',
    persistence: 'It is tracked only for the active expedition while it remains in force.',
    itemSlugs: ['scent-mask'],
  },
  {
    id: 'guard-stonebark', slug: 'stonebark-guard', name: 'Stonebark guard', category: 'Encounter protection',
    summary: 'A one-affliction guard rather than a permanent immunity.',
    sources: 'Use Stonebark Tonic on an eligible party member during an encounter.',
    effect: 'It turns aside the next affliction that would take hold, then the guard is spent.',
    duration: 'It lasts until that one eligible affliction is prevented or the encounter ends.',
    boundary: 'It protects encounter afflictions; it is not a remedy for an already active world effect.',
    clearing: 'There is nothing to clear. Use the item only when its shown target and current encounter state allow it.',
    persistence: 'It belongs to the current encounter only.',
    itemSlugs: ['stonebark-tonic'],
  },
];

export const statusForSlug = (slug: string) => statusReferences.find((status) => status.slug === slug);
