import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { terrainProfiles, worldConditions } from '@/lib/world-reference';

export default function WorldReferencePage() {
  const terrainVisual = terrainProfiles.find((terrain) => terrain.assetURL);
  return <SiteFrame sidebar><PageIntro eyebrow="Field reference" title="World conditions, terrain, and Flora" summary="Use this reference to understand the current world facts you can inspect without predicting a bound map’s hidden tiles, deposits, sites, creatures, or exact Flora." />
    <section className="article-section note-card"><h2>Worlds are combinations, not biomes</h2><p>A bound world is shaped by eight conditions at once. Writing asks for pressures rather than one guaranteed tile, plant, deposit, site, or animal. The bound world keeps its generated answer when you revisit it instead of rolling a replacement map.</p><nav aria-label="World guide links"><Link href="/systems/world-writing">World Writing</Link><Link href="/systems/exploration">Exploration</Link><Link href="/services/survey-post">Survey Post</Link></nav></section>
    <section className="article-section world-reference-grid"><article><h2>World conditions</h2><p>Read the eight conditions that shape a bound world without revealing its complete pressure receipt.</p><nav>{worldConditions.map((condition) => <Link href={`/world/conditions/${condition.slug}`} key={condition.id}>{condition.name}</Link>)}</nav></article><article>{terrainVisual?.assetURL && <PixelImage src={terrainVisual.assetURL} alt="Current world terrain visual" size={64} />}<h2>Terrain</h2><p>Check revealed ground for its current movement, sight, and resource-host relationship.</p><Link href="/terrain">Browse terrain profiles</Link></article><article><h2>Flora and harvesting</h2><p>Plants own their own harvest. A ground label alone does not name an output.</p><Link href="/flora">Browse Flora harvest relationships</Link></article></section>
  </SiteFrame>;
}
