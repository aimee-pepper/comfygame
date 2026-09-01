import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { actionReferences } from '@/lib/action-reference';

const groups = ['Writing', 'World', 'Combat', 'Preparation and custody', 'Research and Village', 'Companions', 'Current service', 'Current station transaction'] as const;

export default function ActionDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Action reference' }]} />
    <PageIntro eyebrow="Player reference" title="Action reference" summary="Find what a current action does, where it appears, what it needs, what it changes when committed, and why a shown action may be unavailable." />
    {groups.map((group) => { const actions = actionReferences.filter((action) => action.group === group); if (!actions.length) return null; return <section className="article-section" key={group}><h2>{group}</h2><div className="table-wrap data-table"><table><thead><tr><th>Action</th><th>Where it appears</th><th>Ready when</th><th>Committed result</th></tr></thead><tbody>{actions.map((action) => <tr key={action.id}><td><Link href={`/actions/${action.slug}`}>{action.name}</Link></td><td>{action.surface}</td><td>{action.availability}</td><td>{action.change}</td></tr>)}</tbody></table></div></section>; })}
    <section className="article-section note-card"><h2>Use the exact current face</h2><p>This reference describes current player-visible actions, not a replacement for the mounted quote. If a target, holding, recipe, or world state has changed, read the displayed refusal and choose again; the game does not turn it into a different action.</p></section>
    <RelatedGuides links={[{ label: 'Getting started', href: '/getting-started' }, { label: 'Journey', href: '/journey' }, { label: 'All systems', href: '/systems' }, { label: 'Village buildings', href: '/village' }, { label: 'Resources', href: '/resources' }]} />
  </SiteFrame>;
}
