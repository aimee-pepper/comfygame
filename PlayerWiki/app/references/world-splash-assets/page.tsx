import type { Metadata } from 'next';
import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { splashInventory as sourceInventory } from '../../../../AssetLab/src/world-splash-five-layer-inventory-v1.js';

interface AssetRow {
  id: string;
  name: string;
  description: string;
}

interface AssetLayer {
  id: string;
  name: string;
  motion: string;
  rows: readonly AssetRow[];
}

interface AssetInventory {
  layers: readonly AssetLayer[];
  assetBytesIncluded: number;
}

const inventory = sourceInventory as AssetInventory;
const familyCount = inventory.layers.reduce((total, layer) => total + layer.rows.length, 0);

const layerPlan = [
  ['Foreground', 'Moves', 'The closest ground and water edges, relief faces, deposits, flora, precipitation, entry mark, and any disclosure-safe opportunity cues. It needs the most detailed silhouettes and edge transitions.'],
  ['Midground 1', 'Moves', 'The first broad terrain, water, relief, deposit, and flora structures. It carries readable regional material changes without looking like a repeated foreground strip.'],
  ['Midground 2', 'Moves', 'Farther terrain, water, relief, flora, and suspended-air depth. It simplifies detail while preserving the identity of the generated world.'],
  ['Background', 'Moves', 'The distant terrain mass, water relationship, enclosure, flora silhouette, and atmosphere. It establishes the world’s horizon and large-scale arrangement.'],
  ['Sky', 'Static', 'The unmoving illumination and upper-air field behind the four moving planes. Celestial objects appear only if the final world receipt explicitly authorizes them.'],
] as const;

const coverageAudit = [
  ['Five-layer parallax structure', 'Sound foundation', 'Four independently moving depth planes plus one static Sky can support a modular final renderer. The exact canvas, overscan, movement, and crop still need to be authored for that renderer.'],
  ['Landscape arrangements', 'Not covered', 'Uniform, Striated, Scattered, Clustered, Graded, and Fractured are only working design terms. The inventory has no masks, transition grammar, weighting, or final accepted arrangement catalogue.'],
  ['Granular ground materials', 'Not covered', 'One generic ground row per depth cannot portray the intended range of distinct dirts, sands, stones, mineral surfaces, muds, ice, Ash, and later accepted terrain materials.'],
  ['Granular liquids and hydrology', 'Partly covered', 'Banks, pools, channels, shelves, islands, and shallow/deep water are useful foundations. Distinct liquid identities, salinity, flow, freeze states, shore materials, and legal transitions are not a finished catalogue.'],
  ['Relief and region boundaries', 'Partly covered', 'Near, middle, and distant relief rows exist, but there is no final vocabulary for ridges, shelves, cliffs, enclosed basins, fractures, blends, and other accepted topography.'],
  ['Flora, trees, and canopy', 'Not covered', 'Four generic flora forms cannot represent the planned terrain-compatible ecology. Trees need crown, trunk, under-canopy, habitat, stature, density, colour, depth, and persistent harvested-state treatments.'],
  ['Weather and atmosphere', 'Partly covered', 'Precipitation and suspended-air rows exist, but the final system needs intensity, motion, density, visibility, and compatible resolved treatments for rain, snow, Ash, mist, smoke, miasma, and any accepted combinations.'],
  ['Temperature, illumination, and Cycle', 'Not covered', 'A single Sky family cannot carry the full hot/cold presentation, five illumination bands, sourceless/constant/cyclic light, and any later approved cycle or celestial grammar.'],
  ['World size', 'Not covered', 'The intended range from slightly smaller than the current map to roughly four times its area has no settled parallax rule for visible breadth, density, horizon, or region scale.'],
  ['Resource and habitat causality', 'Not covered', 'The art list does not yet guarantee that terrain, vegetation, water, and deposits visibly agree with the regions and harvest opportunities that the final generator creates.'],
  ['Final files and production status', 'Not started', `The recovered inventory contains ${inventory.assetBytesIncluded} finished asset bytes. All ${familyCount} rows are planning placeholders, not delivered paintings.`],
] as const;

const paintingPackages = [
  ['1. Parallax composition foundation', 'One final coordinate system for the visible crop and all five planes; exact authored canvas, safe crop, transparent overscan, movement envelope, filtering, scale, and compositing order. These measurements must come from the final parallax consumer—not the temporary proof renderer or the present World Splash page.'],
  ['2. Landscape arrangement kit', 'Reusable composition masks and boundary rules for every accepted arrangement family. Arrangement chooses where regions sit; it must remain separate from which dirt, stone, sand, liquid, or vegetation fills them.'],
  ['3. Ground-material kit', 'A stable visual family for every accepted granular ground material, with near, middle, far, and distant treatments; palette roles; harvest/deposit cues where disclosure permits; legal neighbours; and transition pieces.'],
  ['4. Liquid and shore kit', 'A stable visual family for each accepted liquid, plus shallow/deep, standing/flowing, pools, lakes, rivers or channels, shelves, islands, banks, frozen margins, and mixed-material shore transitions.'],
  ['5. Relief and topography kit', 'Depth-appropriate silhouettes for every accepted elevation and enclosure form, using the selected surface material without turning a palette change into a false wall.'],
  ['6. Flora, tree, and canopy kit', 'Terrain-compatible mosses or crusts, groundcover, low plants, tall growth, shore or aquatic forms, shrubs, trunks, crowns, canopy-over-player and under-canopy states, plus any accepted dormant, dead, harvested, or regrown state. Each visible family needs depth-specific silhouettes and generated colour support.'],
  ['7. Atmosphere and weather kit', 'Separate composable treatments for clear air, mist, smoke, airborne Ash, miasma, rain, snow, and every explicitly accepted transformed combination. Direction, density, intensity, motion, and visibility are distinct axes; contradictory overlays are resolved before rendering.'],
  ['8. Temperature, light, Cycle, and Sky kit', 'Treatments for the complete accepted temperature range, five illumination bands, and sourceless, constant, or cyclic light. Sky features and celestial bodies stay unpainted until their identity and disclosure are actually part of the final receipt.'],
  ['9. Generated-world scale kit', 'Rules and any required art variants that make accepted small, medium, and large worlds read differently without pretending the Splash is a literal map or exposing hidden coordinates.'],
  ['10. Entry and disclosure-safe overlay kit', 'The entry mark plus only those generic site or exceptional-resource cues the final receipt is allowed to disclose. These overlays cannot name, locate, or guarantee hidden content.'],
  ['11. Transition and compatibility kit', 'Edges and resolved composites for every legal neighbouring material and environmental combination. Modular pieces should avoid a painting for every Cartesian combination while still preventing impossible seams and contradictory weather.'],
  ['12. Production manifest and coverage corpus', 'For every final stable art key: filename, dimensions, format, alpha, plane, motion envelope, palette channels, compatible neighbours, state, and representative acceptance worlds. The corpus must exercise each accepted layout, material, liquid, ecology, weather, light, temperature, cycle, and size family deterministically.'],
] as const;

const finalDecisions = [
  ['Ground and liquid catalogue', 'The final named dirts, sands, stones, mineral surfaces, liquids, ice, mud, Ash, and other physical terrain families.'],
  ['Landscape arrangements', 'The final arrangement names, count, weights, region-border rules, and how strongly each changes the parallax silhouette.'],
  ['Parallax measurements', 'The final visible crop, output scale, per-plane source canvas, movement distance, overscan, anchor, and filtering. Current proof dimensions are not valid substitutes.'],
  ['Flora and tree forms', 'The complete visual body-form catalogue, canopy footprints, persistent harvest states, and depth simplification rules.'],
  ['Environment compatibility', 'The legal and transformed weather, atmosphere, temperature, liquid, terrain, and flora combinations. Impossible combinations choose a valid result from the world pressures rather than rejecting the world.'],
  ['Temperature and Cycle presentation', 'Which visible treatments express hot/cold worlds and whether Cycle uses light alone or any explicitly typed Sky feature.'],
  ['World-size presentation', 'How each accepted size tier changes visible breadth, density, horizon, or region scale in the parallax view.'],
] as const;

const originalRowDisposition = (row: AssetRow) => {
  if (row.id.includes('entry-mark')) return 'Retain as a disclosure-safe overlay; remeasure for the final renderer.';
  if (row.id.includes('site-opportunity') || row.id.includes('resource-opportunity')) return 'Retain only if the final receipt authorizes this generic cue; never reveal identity or location.';
  if (row.id.includes('precipitation') || row.id.includes('suspended-air') || row.id.includes('illumination')) return 'Expand into the complete environment kit and final compatibility grammar.';
  return 'Expand into a complete final catalogue with depth-specific art, transitions, and stable render keys.';
};

export const metadata: Metadata = {
  title: 'World Splash Asset Inventory',
  description: 'The audited art inventory for Bookbinder’s intended five-layer parallax World Splash renderer.',
};

export default function WorldSplashAssetInventoryPage() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Aimee Reference', href: '/references' }, { label: 'World Splash Asset Inventory' }]} />
    <PageIntro eyebrow="Aimee Reference" title="World Splash Asset Inventory" summary="A normal planning page for the final five-layer parallax renderer: what the recovered list got right, why it cannot yet cover the intended generated worlds, and the complete art packages still required." />

    <section className="article-section note-card">
      <h2>Audit conclusion: the recovered list is not enough</h2>
      <p>The intended final renderer is a <strong>five-layer parallax scene</strong>: four moving depth planes over one static Sky. That architecture is worth keeping.</p>
      <p>The recovered inventory is not a complete painting brief. It names <strong>{familyCount} generic rows</strong>, supplies <strong>{inventory.assetBytesIncluded} final asset bytes</strong>, and compresses the future range of terrain, liquids, arrangements, ecology, weather, temperature, light, Cycle, and world size into broad placeholders.</p>
      <p><strong>The current generated-image proof and its dimensions are not the target.</strong> They were a temporary proof of concept and must not constrain the final parallax canvas, motion, composition, variant count, or art direction.</p>
      <p><strong>Production decision:</strong> do not ask Aimee to paint these {familyCount} rows and call the renderer complete. First settle the open world catalogues and final parallax measurements, then turn the twelve packages below into an exact file manifest.</p>
    </section>

    <section className="article-section">
      <h2>The final parallax structure</h2>
      <div className="table-wrap"><table><thead><tr><th>Plane</th><th>Motion</th><th>What it must portray</th></tr></thead><tbody>{layerPlan.map(([layer, motion, purpose]) => <tr key={layer}><td><strong>{layer}</strong></td><td>{motion}</td><td>{purpose}</td></tr>)}</tbody></table></div>
    </section>

    <section className="article-section">
      <h2>Completeness audit</h2>
      <p>This audit compares the recovered list with the <strong>accepted intended world direction</strong>, not with the temporary renderer or the limited worlds it currently produces.</p>
      <div className="table-wrap"><table><thead><tr><th>World range</th><th>Coverage</th><th>Finding</th></tr></thead><tbody>{coverageAudit.map(([area, status, finding]) => <tr key={area}><td><strong>{area}</strong></td><td>{status}</td><td>{finding}</td></tr>)}</tbody></table></div>
    </section>

    <section className="article-section">
      <h2>Complete painter-facing inventory</h2>
      <p>These are the production packages required to cover the intended renderer without commissioning a separate painting for every possible world. Each package becomes an exact asset list only after its named catalogue or measurement is settled.</p>
      <div className="definition-grid">{paintingPackages.map(([title, body]) => <article key={title}><h3>{title}</h3><p>{body}</p></article>)}</div>
    </section>

    <section className="article-section">
      <h2>What still needs to be decided with Aimee</h2>
      <p>These are real world-generation or visual-language choices. A final asset count would be fictional until they are settled.</p>
      <div className="table-wrap"><table><thead><tr><th>Decision</th><th>What must be settled</th></tr></thead><tbody>{finalDecisions.map(([decision, detail]) => <tr key={decision}><td><strong>{decision}</strong></td><td>{detail}</td></tr>)}</tbody></table></div>
    </section>

    <section className="article-section">
      <h2>Recovered V1 inventory and disposition</h2>
      <p>This is the complete original 25-row inventory, preserved in an ordinary readable table. Its rows are useful starting responsibilities, not a final count of paintings.</p>
      {inventory.layers.map((layer) => <section key={layer.id} aria-labelledby={`layer-${layer.id}`}>
        <h3 id={`layer-${layer.id}`}>{layer.name} — {layer.motion}</h3>
        <div className="table-wrap"><table><thead><tr><th>Original family</th><th>Original purpose</th><th>Final disposition</th></tr></thead><tbody>{layer.rows.map((row) => <tr key={row.id}><td><strong>{row.name}</strong></td><td>{row.description}</td><td>{originalRowDisposition(row)}</td></tr>)}</tbody></table></div>
      </section>)}
    </section>

    <section className="article-section">
      <h2>Coverage rules for the finished inventory</h2>
      <ol className="numbered-guide">
        <li>Every accepted landscape arrangement must work with every compatible dominant and secondary physical terrain family.</li>
        <li>Every accepted ground and liquid family must have readable near, middle, far, and distant treatment plus legal transitions.</li>
        <li>Every accepted flora form must be proven in its legal terrain, water, light, atmosphere, weather, and temperature ranges, including tree canopy and trunk states.</li>
        <li>Every weather and atmosphere state must use one compatible resolved treatment. Conflicts select a valid pressure-led result; they do not stack impossible art or reject the world.</li>
        <li>Every accepted world-size tier must remain visually legible without exposing hidden coordinates or pretending the Splash is the whole map.</li>
        <li>Low, middle, and high results across Illumination, Thermal, Hydrology, Substrate, Relief, Vitality, Atmosphere, and Cycle must all have a visual owner where they are arrival-visible.</li>
        <li>The same frozen world receipt must reproduce the same five-plane composition on relaunch. A changed receipt may change only the layers owned by its changed facts.</li>
        <li>No art may reveal an undiscovered traveller, creature, apex, site identity, resource coordinate, loot result, hazard, or hidden Sigil merely to make a scene busier.</li>
      </ol>
    </section>

    <section className="article-section note-card">
      <h2>Next production step</h2>
      <p>Settle the seven decisions above with Aimee, define the final parallax consumer and its motion envelopes, then issue the manifest package by package. That manifest—not the temporary proof renderer and not this 25-row placeholder list—will be the authoritative checklist for painting the complete World Splash range.</p>
    </section>

    <RelatedGuides links={[{ label: 'Aimee Reference', href: '/references' }, { label: 'World generation', href: '/world' }, { label: 'World Writing', href: '/systems/world-writing' }, { label: 'Flora', href: '/flora' }, { label: 'Terrain', href: '/terrain' }, { label: 'World implementation roadmap', href: '/references/resource-crafting-world-roadmap' }]} />
    <nav className="next-links"><Link href="/references">Back to Aimee Reference</Link></nav>
  </SiteFrame>;
}
