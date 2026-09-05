import { CarryingProgression } from '@/components/carrying-progression';
import { SeptemberDecisions } from '@/components/september-decisions';
import type { Metadata } from 'next';
import Link from '@/components/wiki-link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { stationForPerson } from '@/lib/people';
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
  const station = stationForPerson(person, content.stations);
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
        /></div>
    <SeptemberDecisions topic="people" />
    {['corrin', 'sela'].includes(person.slug) && <CarryingProgression />}
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
        <p>This page includes all of {person.name}’s currently available book pages and location clues. The clues are separated below so you can stop before reading spoilers and discover the pages naturally in the game.</p>
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
            <dt>Book reward</dt>
            <dd>{person.diaryReward}</dd>
          </div>
        </dl>
      </section>
      <section className="article-section">
        <h2>At the Cottage</h2>
        <p>{person.contribution}</p>
        {station ? (
          <p>
            You can work with {person.name} at <Link href={`/buildings/${station.slug}`}>{station.name}</Link>.
            {service && <> {service.summary}</>}
          </p>
        ) : <p><strong>Planned:</strong> This role is part of the intended game but is not available to use yet.</p>}
      </section>
      <section className="article-section" id="diary-pages">
        <h2>Book pages</h2>
        <p>{person.diaryPageLabel}. Story pages are listed here in reading order; location clues are kept in the spoiler section below.</p>
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
      {hintPages.length > 0 && <section className="article-section spoiler-boundary" id="location-hints"><h2>Spoilers — location clues</h2><p>These pages describe the kind of world where {person.name} can be found. Read them only if you want help with the search.</p><div className="diary-grid">{hintPages.map((page) => <article className="note-card" key={`${person.slug}-hint-${page.sequence}`}><p className="eyebrow">Page {page.sequence} · {page.title}</p><p>{page.prose}</p></article>)}</div></section>}
      <RelatedGuides links={[{ label: 'All people', href: '/people' }, ...(station ? [{ label: `Visit ${station.name}`, href: `/buildings/${station.slug}` }] : []), { label: 'Site directory', href: '/sites' }, { label: 'Library and records', href: '/buildings/library' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'Village', href: '/village' }, { label: 'All systems', href: '/systems' }]} />
    </SiteFrame>
  );
}
