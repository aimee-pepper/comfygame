import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';

export function generateStaticParams() {
  return content.travellers.map((person) => ({ slug: person.slug }));
}
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const person = content.travellers.find((entry) => entry.slug === slug);
  return person ? { title: person.name, description: person.summary } : {};
}

export default async function PersonDetail({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const person = content.travellers.find((entry) => entry.slug === slug);
  if (!person) notFound();
  return (
    <SiteFrame sidebar>
      <div className="person-intro">
        <PixelImage
          src={person.assetURL}
          alt={`${person.name} character cameo`}
          size={112}
        />
        <PageIntro
          eyebrow={person.calling}
          title={person.name}
          summary={person.summary}
        />
      </div>
      <section className="article-section">
        <h2>At a glance</h2>
        <dl className="fact-grid">
          <div>
            <dt>Campaign phase</dt>
            <dd>{humanize(person.campaignPhase)}</dd>
          </div>
          <div>
            <dt>Arrival</dt>
            <dd>
              {person.storyArrivalBand === 0
                ? 'Opening campaign'
                : `Campaign band ${person.storyArrivalBand}`}
            </dd>
          </div>
          <div>
            <dt>Diary pages</dt>
            <dd>{person.pageCount}</dd>
          </div>
          <div>
            <dt>Story clues</dt>
            <dd>{person.clueCount}</dd>
          </div>
        </dl>
      </section>
      <section className="article-section">
        <h2>Where to find {person.name}</h2>
        {person.station ? (
          <p>
            {person.name} is associated with the{' '}
            <Link href={`/places/${person.station.slug}`}>
              {person.station.name}
            </Link>{' '}
            in {person.station.zone}.
          </p>
        ) : (
          <p>
            {person.name} is encountered while travelling rather than at a
            permanent village station.
          </p>
        )}
      </section>
      <section className="article-section">
        <h2>Hints for finding them</h2>
        {person.hints.length ? (
          <ol className="finding-list">
            {person.hints.map((hint, index) => (
              <li key={`${person.id}-hint-${index}`}>{hint}</li>
            ))}
          </ol>
        ) : (
          <p>No authored location hint is currently available.</p>
        )}
      </section>
      <section className="article-section">
        <h2>Diary pages</h2>
        <div className="diary-grid">
          {person.diaryPages.map((page, index) => (
            <article className="note-card" key={`${person.id}-page-${index}`}>
              <p className="eyebrow">Entry {index + 1} · {humanize(page.kind)}</p>
              <p>{page.prose}</p>
              {page.reward && (
                <p>
                  <strong>{humanize(page.reward)}</strong>
                </p>
              )}
            </article>
          ))}
        </div>
      </section>
      {person.teaching && (
        <section className="article-section">
          <h2>What they can teach</h2>
          <p>
            {person.name} can contribute a {humanize(person.teaching.kind)}{' '}
            connected to {humanize(person.teaching.field)}.
          </p>
        </section>
      )}
      <nav className="next-links">
        <Link href="/people">Back to all people</Link>
        {person.station && (
          <Link href={`/places/${person.station.slug}`}>
            Visit {person.station.name}
          </Link>
        )}
      </nav>
    </SiteFrame>
  );
}
