import Link from '@/components/wiki-link';

export function FieldInteractionDecisions({ study = false }: { study?: boolean }) {
  return <section className="article-section note-card">
    <h2>Field controls and resource placement</h2>
    <p><strong>Current tool gesture:</strong> hold Interact for 0.40 seconds, keep holding while sliding onto a packed tool, then release to select it. No second tap, harvest or turn cost. Release outside a choice to cancel. Your choice is saved when you release over a tool and remembered when you reopen the game. This correction is included in build 315.</p>
    <p><strong>Decided resource rule:</strong> one tile, one gatherable resource node across minerals, plants and loose deposits. One node may yield several units; canopy overhang is not a second node.</p>
    <p><strong>Current uncertainty:</strong> apparent overlap may be valid adjacent mining, which remains accepted. Actual duplicate source positions are unconfirmed; no repair is claimed here.</p>
    {study && <p><strong>Requested study changes, not yet delivered:</strong> deeper example water, a north-up/east-right view with downward pitch, and a connected flat dry area for four-direction walking. Keep the tree fading. The example heights do not establish production water depths or new swimming rules.</p>}
    {study && <p><strong>Remembered trees — current in build 316:</strong> fully seen trees keep their last-observed appearance after you walk away and reopen the game. Hidden changes stay hidden; seeing a tree again refreshes its record. Current-tree fading remains. Engineering reports build 316 installed and launched successfully.</p>}
    <p><strong>Also decided, pending implementation:</strong> world-coloured tree wood carried into Logs and equipment, equivalent Hide shown in quantity stacks, clear labels for already-visible Apex creatures, and category controls for optional monster and gathering notices. Older wood stock keeps its lawful uses; muting notices keeps damage, danger and required decisions visible.</p>
    <p><Link href="/references/design-decisions-september-4">Read the field and terrain decisions</Link>.</p>
  </section>;
}
