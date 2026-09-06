import Link from '@/components/wiki-link';

export function FieldInteractionDecisions({ study = false }: { study?: boolean }) {
  return <section className="article-section note-card">
    <h2>Field controls and resource placement</h2>
    <p><strong>Reaffirmed intended tool gesture:</strong> hold Interact for 0.40 seconds, keep holding while sliding onto a packed tool, then release to select it. No second tap, harvest or turn cost. Release outside a choice to cancel. The gesture correction is not yet reported delivered.</p>
    <p><strong>Decided resource rule:</strong> one tile, one gatherable resource node across minerals, plants and loose deposits. One node may yield several units; canopy overhang is not a second node.</p>
    <p><strong>Current uncertainty:</strong> apparent overlap may be valid adjacent mining, which remains accepted. Actual duplicate source positions are unconfirmed; no repair is claimed here.</p>
    {study && <p><strong>Requested study changes, not yet delivered:</strong> deeper example water, a north-up/east-right view with downward pitch, and a connected flat dry area for four-direction walking. Keep the tree fading. Fully seen trees should retain their last-observed appearance on remembered ground, without showing unseen changes or current hidden hazards; that correction is also pending. The example heights do not establish production water depths or new swimming rules.</p>}
    <p><Link href="/references/design-decisions-september-4">Read the field and terrain decisions</Link>.</p>
  </section>;
}
