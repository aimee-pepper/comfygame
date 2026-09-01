// Stable source ownership is retained here; pages expose readable player-facing labels only.
export const recyclerFirstUse = {
  stationID: 'recycler',
  travellerID: 'noll',
  buildCost: '15 Essence',
  journey: [
    'Recruit Noll. His accepted arrival reveals the Recycler foundation in Home → Make.',
    'Open the foundation, review its exact 15-Essence cost, and build only when the current wallet can cover it.',
    'A completed build opens the tier-0 Recycler. It grants no gear, material, recipe, Field Separation Kit, or free recovery.',
    'Select one eligible Stored or Waiting gear piece, read its exact recovery preview, and dismantle only after confirming that displayed piece.',
  ],
  emptyState: 'No gear to dismantle. Store or recover an eligible standard piece of gear, then return to preview what Noll can salvage.',
  selection: [
    'Player-made gear with a valid construction or rebuild receipt returns only recoverable units from that exact receipt.',
    'Eligible ordinary found gear uses its authored standard salvage profile.',
    'Stored and Waiting same-name pieces remain separate current holdings; the preview belongs to the selected exact piece and side.',
  ],
  protected: 'Equipped, unidentified, favorite, locked, protected-return, one-of-a-kind, apex, story, Channelworks, legacy-powered, and unsupported gear stays intact. The current protection explanation names why; the Recycler never changes those choices automatically.',
  zeroOutput: 'A current low-capacity receipt preview can show no recoverable output. That remains an explicit irreversible choice: Dismantle without recovery, not an ordinary reward.',
  boundaries: [
    'Preview, Cancel, and Back change nothing.',
    'Only a completed recovery removes the exact selected piece and adds its displayed output once.',
    'A stale, invalid, busy, or save-failed recovery keeps the preview open and leaves the gear and reserves unchanged.',
    'After relaunch, a preview must be selected again. A committed recovery retains the absent gear and returned output once; an uncommitted preview does not auto-confirm.',
  ],
  exclusion: 'Noll’s Field Separation Kit remains absent from the Recycler, construction, ordinary acquisition, and this first-use journey.',
};
