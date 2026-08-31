import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { serviceGuides } from '@/lib/services';

export default function ServicesPage() {
  return (
    <SiteFrame sidebar>
      <PageIntro
        eyebrow="Village guide"
        title="Services and preparation"
        summary="Understand what each everyday village screen does, what it changes, and where to prepare before the next expedition."
      />
      <section className="article-section">
        <div className="topic-grid">
          {serviceGuides.map((guide) => {
            const station = content.stations.find(
              (entry) => entry.id === guide.stationID,
            );
            return (
              <Link
                className="topic-card"
                href={`/services/${guide.slug}`}
                key={guide.slug}
              >
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
      </nav>
    </SiteFrame>
  );
}
