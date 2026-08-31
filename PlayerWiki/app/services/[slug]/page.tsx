import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { serviceForSlug, serviceGuides } from '@/lib/services';

export function generateStaticParams() {
  return serviceGuides.map((guide) => ({ slug: guide.slug }));
}
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const guide = serviceForSlug(slug);
  return guide ? { title: guide.name, description: guide.summary } : {};
}
export default async function ServiceDetail({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const guide = serviceForSlug(slug);
  if (!guide) notFound();
  const station = content.stations.find(
    (entry) => entry.id === guide.stationID,
  );
  if (!station) notFound();
  return (
    <SiteFrame sidebar>
      <div className="entity-heading">
        {station.assetURL && (
          <PixelImage
            src={station.assetURL}
            alt={`${station.name} visual`}
            size={96}
          />
        )}
        <PageIntro
          eyebrow={station.zone}
          title={guide.name}
          summary={guide.summary}
        />
      </div>
      <section className="article-section">
        <h2>Use it for</h2>
        <ul>
          {guide.useFor.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>
      <section className="article-section">
        <h2>Typical flow</h2>
        <ol className="numbered-guide">
          {guide.workflow.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </section>
      <section className="article-section">
        <h2>Worth remembering</h2>
        <div className="definition-grid">
          {guide.remember.map((item) => (
            <div key={item}>{item}</div>
          ))}
        </div>
      </section>
      <nav className="next-links">
        <Link href="/services">All village services</Link>
        <Link href={`/places/${station.slug}`}>
          {station.name} construction and keeper
        </Link>
      </nav>
    </SiteFrame>
  );
}
