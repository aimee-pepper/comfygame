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
    <WorldViewDirection />
    <SolidDeposits />
    <DirectoryIndex label="Browse terrain" entries={terrainProfiles.map((terrain) => ({ href: `/terrain/${terrain.slug}`, name: terrain.name, imageURL: terrain.assetURL, imageAlt: `${terrain.name} terrain visual` }))} />
    <DirectoryDetailsIntro title="Compare terrain" summary="These short cards show movement and sight at a glance; the full profile adds resource-host relationships and field boundaries." />
    <section className="article-section terrain-directory">{terrainProfiles.map((terrain) => <Link className="terrain-directory-card" href={`/terrain/${terrain.slug}`} key={terrain.id}>{terrain.assetURL && <PixelImage src={terrain.assetURL} alt={`${terrain.name} terrain visual`} size={48} />}<span><strong>{terrain.name}</strong><small>{terrain.movement}</small><small>{terrain.sight}</small></span></Link>)}</section>
  </SiteFrame>;
}
