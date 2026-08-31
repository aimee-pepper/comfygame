import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { buildCost, content } from '@/lib/content';

export default function PlacesPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Places and stations" summary="Find every current village destination, the service it provides, who works there, and what is needed to construct it." />
    <div className="table-wrap data-table"><table><thead><tr><th>Place</th><th>Area</th><th>Purpose</th><th>Keeper</th><th>Availability / cost</th></tr></thead><tbody>{content.stations.map(place => <tr key={place.id}><td><Link href={`/places/${place.slug}`}>{place.name}</Link></td><td>{place.zone}</td><td>{place.blurb}</td><td>{place.keeper ? <Link href={`/people/${place.keeperID?.replaceAll('_', '-')}`}>{place.keeper}</Link> : '—'}</td><td>{buildCost(place)}</td></tr>)}</tbody></table></div>
  </SiteFrame>;
}
