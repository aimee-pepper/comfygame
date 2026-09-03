export type ScreenAuthoringStatus = 'aimee' | 'updated' | 'in-progress' | 'default';

export type ScreenAuthoringNode = {
  title: string;
  status: ScreenAuthoringStatus;
  note?: string;
  children?: ScreenAuthoringNode[];
};

export const screenAuthoringLabels: Record<ScreenAuthoringStatus, string> = {
  aimee: 'Aimee authored',
  updated: 'Asset / Engineering updated',
  'in-progress': 'Partial or asset-ready',
  default: 'Default / legacy UI',
};

// This is a presentation inventory, not a gameplay-unlock chart. Locked stations remain in the
// tree so unfinished UI cannot disappear merely because it is not present in a fresh campaign.
export const screenAuthoringTree: ScreenAuthoringNode[] = [
  {
    title: 'Campaign Select',
    status: 'aimee',
    note: 'Campaign shelf, campaign details, New Game, Continue, recovery, and deletion flow.',
    children: [
      {
        title: 'Active Campaign',
        status: 'updated',
        note: 'The player-facing routes available after a campaign is opened.',
        children: [
          {
            title: 'THE COTTAGE',
            status: 'updated',
            note: 'The shared village hub and its four permanent district tabs.',
            children: [
              {
                title: 'Home district',
                status: 'updated',
                children: [
                  {
                    title: 'Writing Desk',
                    status: 'updated',
                    note: 'Authored header/footer and writing controls are implemented.',
                    children: [
                      { title: 'Write — sigil bins and page canvas', status: 'updated' },
                      {
                        title: 'Pages',
                        status: 'updated',
                        children: [
                          { title: 'Collected Pages', status: 'updated' },
                          { title: 'Templates', status: 'updated' },
                        ],
                      },
                      { title: 'The World — comparison preview', status: 'in-progress' },
                      { title: 'Ink Well sheet', status: 'updated' },
                      { title: 'Page Actions', status: 'updated' },
                    ],
                  },
                  {
                    title: 'Storehouse',
                    status: 'updated',
                    note: 'Current Asset/Engineering UI has been implemented for the main storehouse.',
                    children: [
                      { title: 'Items', status: 'updated' },
                      { title: 'Resources', status: 'updated' },
                      { title: 'Field Kit', status: 'updated' },
                      { title: 'Waiting to be sorted', status: 'updated' },
                      { title: 'Item and material detail sheets', status: 'updated' },
                    ],
                  },
                  {
                    title: 'Party',
                    status: 'default',
                    children: [
                      { title: 'Roster', status: 'default' },
                      {
                        title: 'Character page',
                        status: 'default',
                        children: [
                          { title: 'Gear', status: 'default' },
                          { title: 'Training', status: 'default' },
                          { title: 'Stats', status: 'default' },
                          { title: 'Gambits', status: 'default' },
                        ],
                      },
                    ],
                  },
                  { title: 'Firepit', status: 'updated' },
                  {
                    title: 'Essence Spring',
                    status: 'updated',
                    note: 'The main screen is updated; child systems are tracked separately.',
                    children: [
                      { title: 'Refine', status: 'updated' },
                      { title: 'Study', status: 'default' },
                      { title: 'Unlearn', status: 'default' },
                    ],
                  },
                  {
                    title: 'Workshop',
                    status: 'default',
                    note: 'Still player-facing until the accepted replacement and migration are complete.',
                  },
                ],
              },
              {
                title: 'Make district',
                status: 'updated',
                note: 'The district hub is updated; each destination below keeps its own status.',
                children: [
                  {
                    title: 'Trading Post',
                    status: 'default',
                    children: [
                      { title: 'Buy', status: 'default' },
                      { title: 'Sell', status: 'default' },
                      { title: 'Trade detail sheets', status: 'default' },
                    ],
                  },
                  { title: 'Recycler', status: 'default' },
                  {
                    title: 'Blacksmith',
                    status: 'default',
                    children: [
                      { title: 'Make', status: 'default' },
                      { title: 'Reforge', status: 'default' },
                      { title: 'Learn', status: 'default' },
                    ],
                  },
                  { title: 'Apothecary', status: 'default' },
                  { title: 'Tannery', status: 'default' },
                  { title: 'Bowyer', status: 'default' },
                  { title: 'Armoury', status: 'default' },
                  { title: 'Weaponsmith', status: 'default' },
                  {
                    title: 'Distillery',
                    status: 'in-progress',
                    note: 'Asset state work exists; Engineering implementation is still required.',
                  },
                  {
                    title: 'Channelworks',
                    status: 'in-progress',
                    note: 'Asset state work exists; Engineering implementation is still required.',
                  },
                ],
              },
              {
                title: 'Study district',
                status: 'updated',
                note: 'The district hub is updated; each destination below keeps its own status.',
                children: [
                  {
                    title: 'Library',
                    status: 'in-progress',
                    note: 'The shelf hierarchy has updated work, with active navigation cleanup still in progress.',
                    children: [
                      {
                        title: 'Diaries',
                        status: 'in-progress',
                        children: [
                          { title: 'Diary index', status: 'in-progress' },
                          { title: 'Diary detail', status: 'default' },
                        ],
                      },
                      { title: 'People', status: 'in-progress' },
                      { title: 'Dictionary', status: 'in-progress' },
                      { title: 'Field Notes', status: 'in-progress' },
                      { title: 'World History', status: 'default' },
                      {
                        title: 'Bestiary',
                        status: 'default',
                        note: 'Held for the creature and Bestiary redesign.',
                      },
                    ],
                  },
                  { title: 'Constellation', status: 'default' },
                  {
                    title: 'Survey Post',
                    status: 'in-progress',
                    note: 'Asset layout/states exist; Engineering implementation is still required.',
                  },
                  {
                    title: 'Reliquary',
                    status: 'in-progress',
                    note: 'Asset layout exists; Engineering implementation is still required.',
                  },
                  {
                    title: 'Scriptorium',
                    status: 'in-progress',
                    note: 'Asset layout/states exist; Engineering implementation is still required.',
                    children: [
                      { title: 'Hands', status: 'in-progress' },
                      { title: 'Inks', status: 'in-progress' },
                      { title: 'Runebook', status: 'in-progress' },
                    ],
                  },
                ],
              },
              {
                title: 'Realms district',
                status: 'updated',
                note: 'The district hub is updated; each destination below keeps its own status.',
                children: [
                  {
                    title: "Wayfarer's Table",
                    status: 'in-progress',
                    note: 'Asset layout exists; Engineering implementation is still required.',
                  },
                  {
                    title: 'Anchorage',
                    status: 'in-progress',
                    note: 'Asset layout/states exist; Engineering implementation is still required.',
                  },
                ],
              },
            ],
          },
          {
            title: 'World excursion flow',
            status: 'in-progress',
            children: [
              {
                title: 'World Splash',
                status: 'aimee',
                note: 'Aimee-authored page art and composition direction.',
              },
              {
                title: 'World field',
                status: 'in-progress',
                note: 'Active UI work includes the minimap and field controls.',
                children: [
                  { title: 'Minimap', status: 'in-progress' },
                  {
                    title: 'Field Kit',
                    status: 'in-progress',
                    children: [
                      { title: 'Instruments', status: 'default' },
                      { title: 'Supplies', status: 'default' },
                    ],
                  },
                ],
              },
              { title: 'Encounter / Combat', status: 'default' },
              { title: 'Expedition Return', status: 'default' },
              { title: 'Anchorage settlement', status: 'default' },
            ],
          },
          { title: 'Settings and save games', status: 'default' },
        ],
      },
    ],
  },
];

export function countScreenAuthoringStatuses(nodes = screenAuthoringTree) {
  const counts: Record<ScreenAuthoringStatus, number> = {
    aimee: 0,
    updated: 0,
    'in-progress': 0,
    default: 0,
  };

  const visit = (items: ScreenAuthoringNode[]) => {
    for (const item of items) {
      counts[item.status] += 1;
      if (item.children) visit(item.children);
    }
  };
  visit(nodes);
  return counts;
}
