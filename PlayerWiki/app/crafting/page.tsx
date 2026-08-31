import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { craftingSystems, recipesFor } from '@/lib/crafting';

export default function CraftingSystemsPage() {
  return (
    <SiteFrame sidebar>
      <PageIntro
        eyebrow="Production guide"
        title="Crafting systems"
        summary="Each workshop has its own inputs, selection rules and finished results. Open a system for its complete current recipe list and links back to the resources it uses."
      />
      <section className="article-section">
        <div className="topic-grid">
          {craftingSystems.map((system) => (
            <Link
              className="topic-card"
              href={`/crafting/${system.slug}`}
              key={system.slug}
            >
              <span>
                <strong>{system.name}</strong>
                <small>
                  {system.station} · {recipesFor(system.slug).length} documented
                  recipes
                </small>
                <small>{system.summary}</small>
              </span>
            </Link>
          ))}
        </div>
      </section>
      <nav className="next-links">
        <Link href="/systems/crafting">How crafting works</Link>
        <Link href="/resources">Resource table</Link>
      </nav>
    </SiteFrame>
  );
}
