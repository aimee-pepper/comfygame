import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { techniqueReferences } from '@/lib/technique-reference';

const groups = ['Technique', 'Gambit subject', 'Gambit condition', 'Gambit threshold', 'Gambit action'] as const;

export default function TechniqueDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Techniques and Gambits' }]} />
    <PageIntro eyebrow="Player reference" title="Techniques and Gambits" summary="Open a current technique or Gambit part to see exactly who can use it, when it can fire, its legal target, current result, and listed limit." />
    {groups.map((group) => {
      const references = techniqueReferences.filter((reference) => reference.group === group);
      if (!references.length) return null;
      return <section className="article-section" key={group}><h2>{group === 'Technique' ? 'Current techniques' : `${group}s`}</h2><div className="table-wrap data-table"><table><thead><tr><th>Name</th><th>When it applies</th><th>Target</th><th>Current result</th></tr></thead><tbody>{references.map((reference) => <tr key={reference.id}><td><Link href={`/techniques/${reference.slug}`}>{reference.name}</Link><small>{reference.source}</small></td><td>{reference.trigger}</td><td>{reference.target}</td><td>{reference.result}<small>{reference.limits}</small></td></tr>)}</tbody></table></div></section>;
    })}
    <section className="article-section note-card"><h2>Keep rules distinct</h2><p>A technique is an action selected by its owning actor. A Gambit component is only one part of a prepared rule. If its first eligible rule cannot act, the editor can consider the next enabled rule instead of substituting another action.</p></section>
    <RelatedGuides links={[{ label: 'Combat', href: '/systems/combat' }, { label: 'Party, Gear and Gambits', href: '/systems/party-preparation' }, { label: 'Combat techniques and Gambits guide', href: '/systems/combat-techniques-gambits' }, { label: 'Equipment', href: '/equipment' }, { label: 'Research', href: '/research' }]} />
  </SiteFrame>;
}
