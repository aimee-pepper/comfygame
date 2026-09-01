import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { terrainProfiles } from '@/lib/world-reference';

export default function TerrainDirectoryPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Field reference" title="Terrain" summary="Look reports the exact revealed tile. These profiles explain current movement, sight, and honest resource-host relationships without revealing a campaign’s hidden map." />
    <section className="article-section terrain-directory">{terrainProfiles.map((terrain) => <Link className="terrain-directory-card" href={`/terrain/${terrain.slug}`} key={terrain.id}>{terrain.assetURL && <PixelImage src={terrain.assetURL} alt={`${terrain.name} terrain visual`} size={48} />}<span><strong>{terrain.name}</strong><small>{terrain.movement}</small><small>{terrain.sight}</small></span></Link>)}</section>
  </SiteFrame>;
}
