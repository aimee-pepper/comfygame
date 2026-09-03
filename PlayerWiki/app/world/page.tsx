import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { worldGenerationPlan } from '@/lib/crafting-overview';
import { terrainProfiles, worldConditions } from '@/lib/world-reference';

export default function WorldReferencePage() {
  const terrainVisual = terrainProfiles.find((terrain) => terrain.assetURL);
  return <SiteFrame sidebar><PageIntro eyebrow="Field reference" title="World conditions, terrain, and Flora" summary="Use this reference to understand the current world facts you can inspect without predicting a bound map’s hidden tiles, deposits, sites, creatures, or exact Flora." />
    <DirectoryIndex label="Browse world conditions" entries={worldConditions.map((condition) => ({ href: `/world/conditions/${condition.slug}`, name: condition.name }))} />
    <DirectoryDetailsIntro title="World reference at a glance" summary="Start with a condition, terrain profile, or Flora relationship, then open its full entry for the complete current and intended boundaries." />
    <section className="article-section world-reference-grid"><article><h2>World conditions</h2><p>Read the eight conditions that shape a bound world without revealing everything the game has not shown you yet.</p><nav>{worldConditions.map((condition) => <Link href={`/world/conditions/${condition.slug}`} key={condition.id}>{condition.name}</Link>)}</nav></article><article>{terrainVisual?.assetURL && <PixelImage src={terrainVisual.assetURL} alt="Current world terrain visual" size={64} />}<h2>Terrain</h2><p>Check revealed ground for its movement cost, sight, and relationship to nearby resources.</p><Link href="/terrain">Browse terrain profiles</Link></article><article><h2>Flora and harvesting</h2><p>Each plant has its own harvest. The ground name alone does not tell you what a plant will provide.</p><Link href="/flora">Browse Flora and their harvests</Link></article></section>
    <section className="article-section note-card"><h2>Worlds are combinations, not biomes</h2><p>A bound world is shaped by eight conditions at once. Writing asks for pressures rather than one guaranteed tile, plant, deposit, site, or animal. The bound world keeps its generated answer when you revisit it instead of rolling a replacement map.</p><nav aria-label="World guide links"><Link href="/systems/world-writing">World Writing</Link><Link href="/systems/exploration">Exploration</Link><Link href="/buildings/survey-post">Survey Post</Link></nav></section>
    <section className="article-section"><h2>Current generator and intended ecology</h2><TruthPair current="The current generator creates a repeatable world from eight pressures and saves enough information to rebuild the same result later. Its land, water, terrain, Flora, resources, and creatures do not yet form the complete regional ecology described by the intended design." accepted="Ground arrangement and ground material are separate. Terrain, water, light, atmosphere, weather, temperature, and growth limit which Flora, creatures, and resources fit. If two possible conditions conflict, another relevant pressure chooses between them rather than rejecting the world." acceptedLabel="Intended design" /><div className="table-wrap"><table><thead><tr><th>World layer</th><th>Intended direction</th></tr></thead><tbody>{worldGenerationPlan.map(([layer, direction]) => <tr key={layer}><td><strong>{layer}</strong></td><td>{direction}</td></tr>)}</tbody></table></div></section>
  </SiteFrame>;
}
