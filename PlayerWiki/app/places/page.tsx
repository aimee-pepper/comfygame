import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { buildCost, content } from '@/lib/content';

export default function PlacesPage() {
  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Village', href: '/village' }, { label: 'Places and stations' }]} /><PageIntro eyebrow="Village" title="Places and stations" summary="Find every current Village destination, the service it provides, who works there, and what is needed to construct it." />
    <DirectoryIndex label="Browse Village places" entries={content.stations.map((place) => ({ href: `/buildings/${place.slug}`, name: place.name, imageURL: place.assetURL, imageAlt: `${place.name} building visual` }))} />
    <DirectoryDetailsIntro title="Compare places" summary="This compact table covers area, purpose, keeper, and access. Open the place for construction and current work, or its linked service for step-by-step use." />
    <div className="table-wrap data-table"><table><thead><tr><th aria-label="Image" /><th>Place</th><th>Area</th><th>Purpose</th><th>Keeper</th><th>Availability / cost</th></tr></thead><tbody>{content.stations.map(place => <tr key={place.id}><td>{place.assetURL ? <PixelImage src={place.assetURL} alt={`${place.name} building visual`} /> : '—'}</td><td><Link href={`/buildings/${place.slug}`}>{place.name}</Link></td><td>{place.zone}</td><td>{place.blurb}</td><td>{place.keeper ? <Link href={`/people/${place.keeperID?.replaceAll('_', '-')}`}>{place.keeper}</Link> : '—'}</td><td>{buildCost(place)}</td></tr>)}</tbody></table></div>
    <RelatedGuides links={[{ label: 'Village overview', href: '/village' }, { label: 'Village services', href: '/services' }, { label: 'Village construction', href: '/systems/village-construction' }]} />
  </SiteFrame>;
}
