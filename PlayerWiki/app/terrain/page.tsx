import { SolidDeposits } from '@/components/solid-deposits';
import { WorldViewDirection } from '@/components/world-view-direction';
import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { terrainProfiles } from '@/lib/world-reference';

export default function TerrainDirectoryPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Field reference" title="Terrain" summary="Look reports the exact revealed tile. These profiles explain current movement, sight, and honest resource-host relationships without revealing a campaign’s hidden map." />
    <section className="article-section"><h2>Waterfalls into chasms — planned</h2><p><strong>Decided compatibility:</strong> Frozen water does not produce a waterfall. If a connected body of water cannot support a valid measured flow or has no legal outlet, it keeps its existing appearance and movement rules and does not gain a chasm waterfall. This does not erase water, change its type or invent a river ending. World preparation must still satisfy the existing water amounts and route requirements: a single flowing tile still needs a real outlet. Existing worlds remain unchanged; this clarification does not make chasm waterfalls playable yet.</p><p><strong>Current behavior:</strong> Waterfalls between suitable connected water surfaces keep their existing rules. Waterfalls into chasms are decided intended behavior and are not yet delivered.</p><p><strong>Decided intended behavior:</strong> A real flowing channel may end at an open edge into a chasm. Its waterfall starts at the actual water surface and fades into darkness over about two visible terrain levels. That is a drawing extent, not a known bottom; there is no invented pool, landing or walkable floor. A still pond, ice, blocked edge or river merely passing beside a chasm does not automatically spill. The channel must have that exact outlet.</p><p>The outlet uses no extra water tiles and preserves the amounts of Standing, Flowing and Frozen water. Even a one-cell flow can use a real chasm-edge outlet. The new rule applies to newly prepared worlds under their saved generation rules; existing worlds are not rerolled or given guessed outlets. Live flow requires both the source and chasm edge in full sight. Memory keeps a complete last-observed edge still and dim; separately remembered neighbours do not reveal a new waterfall. Movement, gathering and water colours keep their existing rules.</p></section>
    <WorldViewDirection />
    <SolidDeposits />
    <DirectoryIndex label="Browse terrain" entries={terrainProfiles.map((terrain) => ({ href: `/terrain/${terrain.slug}`, name: terrain.name, imageURL: terrain.assetURL, imageAlt: `${terrain.name} terrain visual` }))} />
    <DirectoryDetailsIntro title="Compare terrain" summary="These short cards show movement and sight at a glance; the full profile adds resource-host relationships and field boundaries." />
    <section className="article-section terrain-directory">{terrainProfiles.map((terrain) => <Link className="terrain-directory-card" href={`/terrain/${terrain.slug}`} key={terrain.id}>{terrain.assetURL && <PixelImage src={terrain.assetURL} alt={`${terrain.name} terrain visual`} size={48} />}<span><strong>{terrain.name}</strong><small>{terrain.movement}</small><small>{terrain.sight}</small></span></Link>)}</section>
  </SiteFrame>;
}
