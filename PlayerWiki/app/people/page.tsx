import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';

export default function PeoplePage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="People" summary="Meet the travellers and village specialists you can encounter. Each page focuses on what they do, when they enter the story, and where to find their services." />
    <section className="people-directory" aria-label="Published people">{content.travellers.map(person => <article className="person-directory-card" key={person.id}><PixelImage src={person.assetURL} alt={`${person.name} character cameo`} size={64} /><div><p className="eyebrow">{person.calling} · {humanize(person.campaignPhase)}</p><h2><Link href={`/people/${person.slug}`}>{person.name}</Link></h2><p>{person.summary}</p><dl><div><dt>Records</dt><dd>{person.pageCount} diary {person.pageCount === 1 ? 'page' : 'pages'}</dd></div><div><dt>Clues</dt><dd>{person.clueCount} location {person.clueCount === 1 ? 'hint' : 'hints'}</dd></div></dl><nav aria-label={`${person.name} guide links`}><Link href={`/people/${person.slug}#location-hints`}>Find them</Link><Link href={`/people/${person.slug}#diary-pages`}>Read diary</Link>{person.station && <Link href={`/places/${person.station.slug}`}>Visit {person.station.name}</Link>}</nav></div></article>)}</section>
  </SiteFrame>;
}
