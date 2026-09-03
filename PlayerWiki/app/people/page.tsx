import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { stationForPerson } from '@/lib/people';
import { serviceForStation } from '@/lib/services';

export default function PeoplePage() {
  const people = [...content.cast].sort((left, right) => left.order - right.order);
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="People" summary="Meet the travellers and Cottage specialists in campaign order. Each person’s page explains where to find them, what they bring home, and where to read their book." />
    <DirectoryIndex label="Browse people" entries={people.map((person) => ({ href: `/people/${person.slug}`, name: person.name, imageURL: person.assetURL, imageAlt: `${person.name} character cameo` }))} />
    <DirectoryDetailsIntro title="People in campaign order" summary="See where each person is found, what they add to the Cottage, and where to read their book." />
    <section className="article-section table-wrap data-table people-directory" aria-label="Campaign-order people directory"><table><thead><tr><th>Order</th><th>Person</th><th>Where you meet them</th><th>What they add</th><th>Book</th></tr></thead><tbody>{people.map((person) => {
      const station = stationForPerson(person, content.stations);
      const service = station ? serviceForStation(station.id) : null;
      return <tr key={person.slug}><td>{person.order}</td><td><Link href={`/people/${person.slug}`}><span className="person-directory-inline">{person.assetURL && <PixelImage src={person.assetURL} alt={`${person.name} character cameo`} size={38} />}<span><strong>{person.name}</strong><small>{person.calling}</small></span></span></Link></td><td><strong>{person.role}</strong><br /><small>{person.meetingContext}</small></td><td>{station ? <><Link href={`/buildings/${station.slug}`}>{station.name}</Link><br /><small>{service?.summary ?? person.contribution}</small></> : <><strong>Planned</strong><br /><small>{person.contribution}</small></>}</td><td><Link href={`/people/${person.slug}#meeting`}>How you meet</Link><br /><small><Link href={`/people/${person.slug}#diary-pages`}>{person.diaryPageLabel}</Link></small></td></tr>;
    })}</tbody></table></section>
    <section className="article-section note-card"><h2>Finding people and reading their books</h2><p>Once the Library names someone to seek, their page can help you recognise the kind of world they prefer. Each book stays together on that person’s page, while location clues are clearly marked so you can avoid spoilers.</p></section>
  </SiteFrame>;
}
