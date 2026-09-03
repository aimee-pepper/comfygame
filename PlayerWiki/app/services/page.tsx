import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { serviceGuides } from '@/lib/services';

export default function ServicesPage() {
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Village', href: '/village' }, { label: 'Village services' }]} />
      <PageIntro
        eyebrow="Village guide"
        title="Village services"
        summary="Understand what each everyday village screen does, what it changes, and where to prepare before the next expedition."
      />
      <DirectoryIndex label="Browse Village services" entries={serviceGuides.map((guide) => { const station = content.stations.find((entry) => entry.id === guide.stationID); return { href: `/services/${guide.slug}`, name: guide.name, imageURL: station?.assetURL ?? station?.contextAssetURL, imageAlt: station?.assetURL ? `${station.name} building visual` : `${station?.zone ?? 'Village'} town setting` }; })} />
      <DirectoryDetailsIntro title="Compare services" summary="Use these concise cards to find the right service and area. The linked service page holds the complete workflow, confirmations, and result boundaries." />
      <section className="article-section">
        <div className="topic-grid">
          {serviceGuides.map((guide) => {
            const station = content.stations.find(
              (entry) => entry.id === guide.stationID,
            );
            const visualURL = station?.assetURL ?? station?.contextAssetURL;
            const visualLabel = station?.assetURL
              ? `${station.name} building visual`
              : `${station?.zone ?? 'Village'} town setting`;
            return (
              <Link
                className="topic-card service-card"
                href={`/services/${guide.slug}`}
                key={guide.slug}
              >
                {visualURL && <PixelImage src={visualURL} alt={visualLabel} size={56} />}
                <span>
                  <strong>{guide.name}</strong>
                  <small>
                    {station?.zone ?? 'Village'} · {guide.summary}
                  </small>
                </span>
              </Link>
            );
          })}
        </div>
      </section>
      <nav className="next-links">
        <Link href="/places">Places and construction</Link>
        <Link href="/crafting">Crafting systems</Link>
        <Link href="/trading">Trading offers</Link>
        <Link href="/recycling">Recycler returns</Link>
      </nav>
      <RelatedGuides links={[{ label: 'Village overview', href: '/village' }, { label: 'Places and stations', href: '/places' }, { label: 'Village construction', href: '/systems/village-construction' }]} />
    </SiteFrame>
  );
}
