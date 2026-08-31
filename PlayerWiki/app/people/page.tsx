import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';

export default function PeoplePage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="People" summary="Meet the travellers and village specialists you can encounter. Each page focuses on what they do, when they enter the story, and where to find their services." />
    <div className="table-wrap data-table"><table><thead><tr><th>Person</th><th>Role</th><th>Campaign</th><th>Where to find them</th><th>What they contribute</th></tr></thead><tbody>{content.travellers.map(person => <tr key={person.id}><td><Link href={`/people/${person.slug}`}>{person.name}</Link></td><td>{person.calling}</td><td>{humanize(person.campaignPhase)}</td><td>{person.station ? <Link href={`/places/${person.station.slug}`}>{person.station.name}</Link> : 'Travelling'}</td><td>{person.summary}</td></tr>)}</tbody></table></div>
  </SiteFrame>;
}
