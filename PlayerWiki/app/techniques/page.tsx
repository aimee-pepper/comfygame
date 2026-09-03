import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, type GambitComponent } from '@/lib/content';
import { techniqueReferences } from '@/lib/technique-reference';

const groups = ['Technique', 'Gambit subject', 'Gambit condition', 'Gambit threshold', 'Gambit action'] as const;
const componentOrder: GambitComponent['kind'][] = ['subject', 'property', 'comparator', 'threshold', 'action'];
const componentLabels: Record<GambitComponent['kind'], string> = { subject: 'Subjects', property: 'Conditions', comparator: 'Comparisons', threshold: 'Values', action: 'Actions' };

export default function TechniqueDirectory() {
  const componentsFor = (kind: GambitComponent['kind']) => content.gambitComponents.filter((component) => component.kind === kind);
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Techniques and Gambits' }]} />
    <PageIntro eyebrow="Player reference" title="Techniques and Gambits" summary="Open a technique or Gambit part to see who can use it, when it can activate, which targets it accepts, what it does, and any limits." />
    <DirectoryIndex label="Browse techniques and Gambit parts" entries={techniqueReferences.map((reference) => ({ href: `/techniques/${reference.slug}`, name: reference.name }))} />
    <DirectoryDetailsIntro title="Compare techniques and Gambit parts" summary="Compare when each one activates, who or what it can target, what it does, and how it is learned. Each full entry includes every requirement and limit." />
    {groups.map((group) => {
      const references = techniqueReferences.filter((reference) => reference.group === group);
      if (!references.length) return null;
      return <section className="article-section" key={group}><h2>{group === 'Technique' ? 'Techniques' : `${group}s`}</h2><div className="table-wrap data-table"><table><thead><tr><th>Name</th><th>When it applies</th><th>Target</th><th>What it does</th></tr></thead><tbody>{references.map((reference) => <tr key={reference.id}><td><Link href={`/techniques/${reference.slug}`}>{reference.name}</Link><small>{reference.source}</small></td><td>{reference.trigger}</td><td>{reference.target}</td><td>{reference.result}<small>{reference.limits}</small></td></tr>)}</tbody></table></div></section>;
    })}
    <section className="article-section two-column"><div><h2>Learning a technique</h2><p>The Binder, Quill, and Ashe begin with techniques of their own. Every other available technique is learned from that person’s Training tree. Learning one costs one Combat Point and requires the earlier choice shown in the tree.</p></div><div><h2>Using it in an encounter</h2><p>The acting person’s Techniques list shows whether each option is Ready or how many rounds remain on its cooldown. Choose one of the targets it lists. If that target is no longer eligible, nothing else is used in its place.</p></div></section>
    <section className="article-section"><h2>How Gambit rules are assembled</h2><p>At Home, each person’s editor offers only their owned parts. A rule reads from subject through action; subject and action are required before a blank rule can be written.</p><div className="definition-grid">{componentOrder.map((kind) => <div key={kind}><h3>{componentLabels[kind]}</h3><ul>{componentsFor(kind).map((component) => <li key={component.name}><strong>{component.name}</strong> — {component.blurb}</li>)}</ul></div>)}</div></section>
    <section className="article-section two-column"><div><h2>Priority and readiness</h2><p>Rules are checked top to bottom. The first enabled rule that fits fires. If it lacks a ready technique or valid target, the next enabled rule can be considered.</p></div><div><h2>Keep or change a rule</h2><p>Switching off keeps a rule written. Dragging changes priority; deleting removes only that rule. Rules beyond the current slot count stay written but idle.</p></div></section>
    <section className="article-section note-card"><h2>Keep rules distinct</h2><p>A technique is an action selected by its owning actor. A Gambit component is only one part of a prepared rule; it does not teach or grant the complete action by itself.</p></section>
    <RelatedGuides links={[{ label: 'Combat', href: '/systems/combat' }, { label: 'Party preparation', href: '/systems/party-preparation' }, { label: 'Conditions and effects', href: '/statuses' }, { label: 'Equipment', href: '/equipment' }, { label: 'Research', href: '/research' }]} />
  </SiteFrame>;
}
