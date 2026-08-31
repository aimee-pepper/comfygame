import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

export function generateStaticParams() {
  return content.cast.map((person) => ({ slug: person.slug }));
}
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const person = content.cast.find((entry) => entry.slug === slug);
  return person ? { title: person.name, description: person.contribution } : {};
}

export default async function PersonDetail({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const person = content.cast.find((entry) => entry.slug === slug);
  if (!person) notFound();
  const station = content.stations.find((entry) => person.role.includes(entry.name));
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Reference', href: '/people' }, { label: 'People', href: '/people' }, { label: person.name }]} />
      <div className="person-intro">
        <PixelImage
          src={person.assetURL}
          alt={`${person.name} character cameo`}
          size={112}
        />
        <PageIntro
          eyebrow={person.calling}
          title={person.name}
          summary={person.contribution}
        />
      </div>
      <nav className="person-record-navigation" aria-label={`${person.name} records`}>
        <a href="#meeting">
          <strong>Meeting</strong>
          <span>Campaign order {person.order}</span>
        </a>
        <a href="#diary-pages">
          <strong>Diary pages</strong>
          <span>{person.diaryPageLabel}</span>
        </a>
      </nav>
      <section className="article-section note-card">
        <h2>Spoiler boundary</h2>
        <p>Use this page after the Library names {person.name} as someone to seek. A page headed “Where someone is” remains a world hint: recover that exact diary page before using its details.</p>
      </section>
      <section className="article-section" id="meeting">
        <h2>At a glance</h2>
        <dl className="fact-grid">
          <div>
            <dt>Campaign order</dt>
            <dd>{person.order}</dd>
          </div>
          <div>
            <dt>Meeting context</dt>
            <dd>{person.meetingContext}</dd>
          </div>
          <div>
            <dt>{person.roleLabel}</dt>
            <dd>{person.role}</dd>
          </div>
          <div>
            <dt>Diary reward</dt>
            <dd>{person.diaryReward}</dd>
          </div>
        </dl>
      </section>
      <section className="article-section">
        <h2>After meeting</h2>
        <p>{person.contribution}</p>
        {station && (
          <p>
            Their current village route is the <Link href={`/places/${station.slug}`}>{station.name}</Link>.
          </p>
        )}
      </section>
      <section className="article-section" id="diary-pages">
        <h2>Diary sequence</h2>
        <div className="diary-grid">
          {person.diaryPages.map((page) => (
            <article className="note-card" key={`${person.slug}-page-${page.sequence}`}>
              <p className="eyebrow">Page {page.sequence} · {page.title}</p>
              {page.worldHint ? <p>This is a world hint. Its details become useful only after this exact diary page is recovered.</p> : <p>{page.detail ?? ''}</p>}
            </article>
          ))}
        </div>
      </section>
      <RelatedGuides links={[{ label: 'All people', href: '/people' }, ...(station ? [{ label: `Visit ${station.name}`, href: `/places/${station.slug}` }] : []), { label: 'Village services', href: '/services' }, { label: 'All systems', href: '/systems' }]} />
    </SiteFrame>
  );
}
