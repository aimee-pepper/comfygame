import Link from '@/components/wiki-link';

export function FieldInteractionDecisions({ study = false }: { study?: boolean }) {
  return <section className="article-section note-card">
    <h2>Field controls and resource placement</h2>
    <p><strong>Current tool gesture:</strong> hold Interact for 0.40 seconds, keep holding while sliding onto a packed tool, then release to select it. No second tap, harvest or turn cost. Release outside a choice to cancel. Your choice is saved when you release over a tool and remembered when you reopen the game. This correction is included in build 315.</p>
    <p><strong>Decided resource rule:</strong> one tile, one gatherable resource node across minerals, plants and loose deposits. One node may yield several units; canopy overhang is not a second node.</p>
    <p><strong>Current uncertainty:</strong> apparent overlap may be valid adjacent mining, which remains accepted. Actual duplicate source positions are unconfirmed; no repair is claimed here.</p>
    {study && <p><strong>Current water study:</strong> the example scene has deeper water, a north-up/east-right view with downward pitch, and a connected flat dry area for four-direction walking, delivered in build312. Tree fading remains. Its chosen example heights do not establish production depths or swimming rules.</p>}
    {study && <p><strong>Remembered trees — current in build 316:</strong> fully seen trees keep their last-observed appearance after you walk away and reopen the game. Hidden changes stay hidden; seeing a tree again refreshes its record. Current-tree fading remains. Engineering reports build 316 installed and launched successfully.</p>}
    <p><strong>Current material stacks:</strong> build345 groups Hide by subtype and source quality in Return and Storehouse. Tap the total for exact colour and useful-property variants; individual pieces remain available to crafting. Tannery uses one eligible Skin/Hide and one Salt to make one Leather, delivered in323.</p>
    <p><strong>Current in build 319:</strong> actual Apex creatures have functional labels on the existing visible field/minimap markers, current-sight details and encounter header. Ordinary stationary creatures do not. Visibility rules are unchanged; Apex styling is also integrated in build 320.</p>
    <p><strong>Current in build 320:</strong> optional notice settings start with monsters on, mining/gathering off, and finds/learning on. Your choices persist. Muting gathering also hides its separate result overlay, while damage, danger and required decisions remain visible. Collected resources are unchanged, and turning notices back on does not replay old messages.</p>
    <p><strong>Current in build321:</strong> new-world wood has a saved source colour shared by the visible tree stem and its harvested Logs. Remembered trees and stock colour chips retain it. Older Logs keep their supported uses; unknown historical colour stays unknown.</p>
    <p><strong>Colour progress:</strong> textile source choices and swatches are delivered in322/323; actual coloured Hafts are delivered in325. Finished component-coloured equipment artwork and the complete source-to-visible-item journey remain unfinished.</p>
    <p><Link href="/references/design-decisions-september-4">Read the field and terrain decisions</Link>.</p>
  </section>;
}
