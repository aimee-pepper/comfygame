import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
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
  const visualURL = station.assetURL ?? station.contextAssetURL;
  const visualLabel = station.assetURL
    ? `${station.name} building visual`
    : `${station.zone} town setting`;
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Village services', href: '/services' }, { label: guide.name }]} />
      <div className="entity-heading">
        {visualURL && (
          <PixelImage
            src={visualURL}
            alt={visualLabel}
            size={96}
          />
        )}
        <PageIntro
          eyebrow={station.zone}
          title={guide.name}
          summary={guide.summary}
        />
      </div>
      <p className="service-visual-note">{station.assetURL ? `The current retained building visual for ${station.name}.` : `The current retained ${station.zone} setting for this service.`}</p>
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
        <h2>Choose the current entry</h2>
        <p>{guide.selection}</p>
      </section>
      <section className="article-section">
        <h2>What happens after you confirm</h2>
        <p>{guide.result}</p>
      </section>
      <section className="article-section">
        <h2>Worth remembering</h2>
        <div className="definition-grid">
          {guide.remember.map((item) => (
            <div key={item}>{item}</div>
          ))}
        </div>
      </section>
      <RelatedGuides links={[
        { label: 'All village services', href: '/services' },
        { label: `${station.name} construction and keeper`, href: `/places/${station.slug}` },
        ...guide.relatedGuides,
        { label: 'All systems', href: '/systems' },
      ]} />
    </SiteFrame>
  );
}
