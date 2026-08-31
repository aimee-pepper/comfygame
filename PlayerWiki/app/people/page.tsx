import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

export default function PeoplePage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="People" summary="Meet the travellers and village specialists in campaign order. A person’s page keeps their work, diary sequence, and the boundaries around discovery together." />
    <section className="article-section note-card"><h2>Read each page at the right moment</h2><p>A traveller’s name and meeting context are for after the Library names someone to seek. World-hint details stay with their matching recovered diary page.</p></section>
    <section className="people-directory" aria-label="Campaign cast">{content.cast.map(person => <article className="person-directory-card" key={person.slug}><PixelImage src={person.assetURL} alt={`${person.name} character cameo`} size={64} /><div><p className="eyebrow">Campaign order {person.order} · {person.calling}</p><h2><Link href={`/people/${person.slug}`}>{person.name}</Link></h2><p>{person.contribution}</p><dl><div><dt>{person.roleLabel}</dt><dd>{person.role}</dd></div><div><dt>Diary</dt><dd>{person.diaryPageLabel}</dd></div></dl><nav aria-label={`${person.name} guide links`}><Link href={`/people/${person.slug}#meeting`}>Meeting</Link><Link href={`/people/${person.slug}#diary-pages`}>Diary sequence</Link></nav></div></article>)}</section>
  </SiteFrame>;
}
