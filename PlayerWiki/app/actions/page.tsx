import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { actionReferences } from '@/lib/action-reference';

const groups = ['Writing', 'World', 'Combat', 'Preparation and storage', 'Research and Village', 'Companions', 'Services', 'Crafting stations'] as const;

export default function ActionDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Action reference' }]} />
    <PageIntro eyebrow="Player reference" title="Action reference" summary="Find where each action appears, what it needs, what happens when it succeeds, and why it may sometimes be unavailable." />
    <DirectoryIndex label="Browse actions" entries={actionReferences.map((action) => ({ href: `/actions/${action.slug}`, name: action.name }))} />
    <DirectoryDetailsIntro title="Compare actions" summary="Scan where each action appears, what makes it ready, and what changes only after you confirm." />
    {groups.map((group) => { const actions = actionReferences.filter((action) => action.group === group); if (!actions.length) return null; return <section className="article-section" key={group}><h2>{group}</h2><div className="table-wrap data-table"><table><thead><tr><th>Action</th><th>Where it appears</th><th>Ready when</th><th>What happens</th></tr></thead><tbody>{actions.map((action) => <tr key={action.id}><td><Link href={`/actions/${action.slug}`}>{action.name}</Link></td><td>{action.surface}</td><td>{action.availability}</td><td>{action.change}</td></tr>)}</tbody></table></div></section>; })}
    <section className="article-section note-card"><h2>Check the game before confirming</h2><p>This reference explains how each action normally works. If your target, item, recipe, or world has changed since you opened its preview, read the new message and choose again. The game will not silently perform a different action.</p></section>
    <RelatedGuides links={[{ label: 'Getting started', href: '/getting-started' }, { label: 'Journey', href: '/journey' }, { label: 'All systems', href: '/systems' }, { label: 'Village buildings', href: '/village' }, { label: 'Resources', href: '/resources' }]} />
  </SiteFrame>;
}
