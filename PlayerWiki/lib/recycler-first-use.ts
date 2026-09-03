// Stable source ownership is retained here; pages expose readable player-facing labels only.
export const recyclerFirstUse = {
  stationID: 'recycler',
  travellerID: 'noll',
  buildCost: '15 Essence',
  journey: [
    'Recruit Noll. His accepted arrival reveals the Recycler foundation in Home → Make.',
    'Open the foundation, review its 15-Essence cost, and build when you can afford it.',
    'A completed build opens the tier-0 Recycler. It grants no gear, material, recipe, Field Separation Kit, or free recovery.',
    'Select one eligible piece from Stored or Waiting, review the materials it will return, and dismantle it only after confirming that choice.',
  ],
  emptyState: 'No gear to dismantle. Store or recover an eligible standard piece of gear, then return to preview what Noll can salvage.',
  selection: [
    'Player-made gear that remembers its construction or rebuild materials returns only recoverable units from that recorded list.',
    'Eligible ordinary found gear uses its defined standard salvage pattern.',
    'Pieces with the same name remain separate items in Stored and Waiting. The preview belongs to the one piece and location you selected.',
  ],
  protected: 'Equipped, unidentified, favorite, locked, protected-return, one-of-a-kind, apex, story, Channelworks, legacy-powered, and unsupported gear stays intact. The Recycler explains why it cannot dismantle the selected piece and never changes those protections automatically.',
  zeroOutput: 'At a low Recycler tier, a preview can show that nothing will be recovered. Dismantling is still permanent, so the game states clearly when an item will be destroyed without returning materials.',
  boundaries: [
    'Preview, Cancel, and Back change nothing.',
    'Only a successful dismantle removes the selected piece and adds the materials shown in the preview.',
    'If the item or preview changes, another action is busy, or the game cannot save, the gear and stored materials stay unchanged.',
    'After reopening the game, select the preview again. A successful dismantle removes the gear and returns its materials once; an unfinished preview never confirms itself.',
  ],
  exclusion: 'Noll’s Field Separation Kit remains absent from the Recycler, construction, ordinary acquisition, and this first-use journey.',
};
