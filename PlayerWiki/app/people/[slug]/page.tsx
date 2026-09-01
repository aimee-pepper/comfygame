import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { serviceForStation } from '@/lib/services';

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
  const service = station ? serviceForStation(station.id) : null;
  const hintPages = person.diaryPages.filter((page) => page.worldHint);
  const bookPages = person.diaryPages.filter((page) => !page.worldHint);
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
          <strong>Book pages</strong>
          <span>{person.diaryPageLabel}</span>
        </a>
        {hintPages.length > 0 && <a href="#location-hints"><strong>Location hints</strong><span>{hintPages.length} spoiler-marked stage{hintPages.length === 1 ? '' : 's'}</span></a>}
      </nav>
      <section className="article-section note-card">
        <h2>Spoiler boundary</h2>
        <p>This page includes the complete currently authored book and location-hint text for {person.name}. The location-hint stages are separated below so you can stop before reading them; they are not a substitute for recovering records in play.</p>
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
            {service && <> Its current player guide is <Link href={`/services/${service.slug}`}>{service.name}</Link>.</>}
          </p>
        )}
      </section>
      <section className="article-section" id="diary-pages">
        <h2>Book pages beyond location hints</h2>
        <p>{person.diaryPageLabel}. The complete authored record is divided into these book pages and the spoiler-marked location-hint stages below; each keeps the current source text in order.</p>
        <div className="diary-grid">
          {bookPages.map((page) => (
            <article className="note-card" key={`${person.slug}-page-${page.sequence}`}>
              <p className="eyebrow">Page {page.sequence} · {page.title}</p>
              <p>{page.prose}</p>
              {page.reward && <small>{page.reward}</small>}
            </article>
          ))}
        </div>
      </section>
      {hintPages.length > 0 && <section className="article-section spoiler-boundary" id="location-hints"><h2>Spoilers — location-hint stages</h2><p>These authored pages describe conditions and related observations. Read them only when you want the complete player-reference material.</p><div className="diary-grid">{hintPages.map((page) => <article className="note-card" key={`${person.slug}-hint-${page.sequence}`}><p className="eyebrow">Page {page.sequence} · {page.title}</p><p>{page.prose}</p></article>)}</div></section>}
      <RelatedGuides links={[{ label: 'All people', href: '/people' }, ...(station ? [{ label: `Visit ${station.name}`, href: `/places/${station.slug}` }] : []), ...(service ? [{ label: service.name, href: `/services/${service.slug}` }] : []), { label: 'Site directory', href: '/sites' }, { label: 'Knowledge and records', href: '/systems/knowledge-records' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'Village services', href: '/services' }, { label: 'All systems', href: '/systems' }]} />
    </SiteFrame>
  );
}
