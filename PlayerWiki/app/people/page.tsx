import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { serviceForStation } from '@/lib/services';

export default function PeoplePage() {
  const people = [...content.cast].sort((left, right) => left.order - right.order);
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="People" summary="Meet the travellers and village specialists in campaign order. A person’s page keeps their work, diary sequence, and the boundaries around discovery together." />
    <DirectoryIndex label="Browse people" entries={people.map((person) => ({ href: `/people/${person.slug}`, name: person.name, imageURL: person.assetURL, imageAlt: `${person.name} character cameo` }))} />
    <DirectoryDetailsIntro title="People in campaign order" summary="Compare each person’s meeting role, Village relationship, and record links before opening their complete page." />
    <section className="article-section table-wrap data-table people-directory" aria-label="Campaign-order people directory"><table><thead><tr><th>Order</th><th>Person</th><th>Meeting and role</th><th>Village relationship</th><th>Record</th></tr></thead><tbody>{people.map((person) => {
      const station = content.stations.find((entry) => person.role.includes(entry.name));
      const service = station ? serviceForStation(station.id) : null;
      return <tr key={person.slug}><td>{person.order}</td><td><Link href={`/people/${person.slug}`}><span className="person-directory-inline">{person.assetURL && <PixelImage src={person.assetURL} alt={`${person.name} character cameo`} size={38} />}<span><strong>{person.name}</strong><small>{person.calling}</small></span></span></Link></td><td><strong>{person.role}</strong><br /><small>{person.meetingContext}</small></td><td>{station ? <><Link href={`/places/${station.slug}`}>{station.name}</Link>{service ? <><br /><small><Link href={`/services/${service.slug}`}>{service.name}</Link></small></> : null}</> : 'No current Village service route is published.'}</td><td><Link href={`/people/${person.slug}#meeting`}>Meeting</Link><br /><small><Link href={`/people/${person.slug}#diary-pages`}>{person.diaryPageLabel}</Link></small></td></tr>;
    })}</tbody></table></section>
    <section className="article-section note-card"><h2>Rules shared by people and records</h2><p>A traveller’s name and meeting context are useful after the Library names someone to seek. Each linked record keeps that person’s authored pages together, including their location-hint stages behind a clear spoiler boundary.</p></section>
  </SiteFrame>;
}
