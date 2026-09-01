import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { statusReferences } from '@/lib/status-reference';

const categories = ['Encounter affliction', 'World effect', 'Encounter protection'] as const;

export default function StatusDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Conditions and effects' }]} />
    <PageIntro eyebrow="Player reference" title="Conditions and effects" summary="Read the exact current condition before choosing a cure, guard, or field action. Encounter afflictions and world effects use separate rules even when their names sound alike." />
    {categories.map((category) => {
      const entries = statusReferences.filter((status) => status.category === category);
      return <section className="article-section" key={category}>
        <h2>{category === 'Encounter affliction' ? 'Encounter afflictions' : category}</h2>
        <div className="table-wrap data-table"><table><thead><tr><th>Condition or effect</th><th>Current result</th><th>Where it applies</th><th>Duration or clearing</th></tr></thead><tbody>{entries.map((status) => <tr key={status.id}><td><Link href={`/statuses/${status.slug}`}>{status.name}</Link><small>{status.summary}</small></td><td>{status.effect}</td><td>{status.boundary}</td><td>{status.duration}<small>{status.clearing}</small></td></tr>)}</tbody></table></div>
      </section>;
    })}
    <section className="article-section note-card"><h2>Use the shown state</h2><p>Choose a remedy, guard, or Field Kit action only for the state shown on its own current screen. An unavailable choice does not become a different use, and cancelling leaves the current condition unchanged.</p></section>
    <RelatedGuides links={[{ label: 'Combat', href: '/systems/combat' }, { label: 'Combat techniques and Gambits', href: '/systems/combat-techniques-gambits' }, { label: 'Field supplies', href: '/systems/field-supplies' }, { label: 'Consumables', href: '/consumables' }, { label: 'Exploration', href: '/systems/exploration' }]} />
  </SiteFrame>;
}
