import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, type GambitComponent } from '@/lib/content';

const componentOrder: GambitComponent['kind'][] = [
  'subject',
  'property',
  'comparator',
  'threshold',
  'action',
];
const componentLabels: Record<GambitComponent['kind'], string> = {
  subject: 'Subjects',
  property: 'Conditions',
  comparator: 'Comparisons',
  threshold: 'Values',
  action: 'Actions',
};

export default function CombatTechniquesAndGambitsGuide() {
  const componentsFor = (kind: GambitComponent['kind']) =>
    content.gambitComponents.filter((component) => component.kind === kind);
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Combat techniques and Gambits' }]} />
    <PageIntro eyebrow="Current combat reference" title="Combat Techniques and Gambits" summary="Use this reference to read the current technique set, its card targets and round cooldowns, then build Gambit rules from the components your party has actually learned." />
    <section className="article-section note-card"><h2>Open an individual reference</h2><p>Use the <Link href="/techniques">Techniques and Gambits directory</Link> to open the exact current entry for one technique or owned Gambit component. Use <Link href="/statuses">Conditions and effects</Link> when a technique or item applies, clears, or prevents an affliction.</p></section>
    <section className="article-section two-column">
      <div><h2>Learning a technique</h2><p>The Binder, Quill, and Ashe have the inherent techniques listed below. Every other current technique comes from the exact Training node a person owns. Learning one current Training node costs one Combat Point and requires one of the node’s displayed parent choices; a person can only use the techniques attached to their own learned nodes.</p></div>
      <div><h2>Using it in an encounter</h2><p>Open Techniques on that acting person’s turn. The palette shows Ready when the technique can be used and its remaining rounds when it is cooling. The only listed limiter is the displayed round cooldown—there is no separate technique currency.</p><p>Choose the target named in the table when one is required. If a target has changed or is no longer eligible, the technique does not become a different action.</p></div>
    </section>
    <section className="article-section">
      <h2>Current learned techniques</h2>
      <div className="table-wrap data-table"><table><thead><tr><th>Technique</th><th>Who can use it</th><th>Target</th><th>Cooldown</th><th>Current effect</th></tr></thead><tbody>{content.combatTechniques.map((technique) => <tr key={technique.name}><td><strong>{technique.name}</strong><br /><small>{technique.blurb}</small></td><td>{technique.availability}{technique.trainingDepth ? <><br /><small>Training depth {technique.trainingDepth}</small></> : null}</td><td>{technique.target}</td><td>{technique.cooldown}</td><td>{technique.effect}</td></tr>)}</tbody></table></div>
    </section>
    <section className="article-section">
      <h2>Gambit rule parts</h2>
      <p>At Home, each person’s Gambit editor offers only their owned components. A written rule reads from subject through action. Required subject and action parts must be available before a blank rule can be written; optional condition parts can stay unset.</p>
      <div className="definition-grid">{componentOrder.map((kind) => <div key={kind}><h3>{componentLabels[kind]}</h3><ul>{componentsFor(kind).map((component) => <li key={component.name}><strong>{component.name}</strong> — {component.blurb}</li>)}</ul></div>)}</div>
    </section>
    <section className="article-section two-column">
      <div><h2>Priority and readiness</h2><p>Rules are checked top to bottom. The first enabled rule that fits is the one that fires. If an action part needs a ready technique or a valid target and neither is available, that rule does not fire and the next rule can be considered.</p></div>
      <div><h2>Keep or change a rule</h2><p>Switching a rule off keeps it written. Dragging changes priority; deleting removes only the selected rule. Rules past a person’s current slot count stay written but idle until a slot is available.</p></div>
    </section>
    <RelatedGuides links={[{ label: 'Combat', href: '/systems/combat' }, { label: 'Conditions and effects', href: '/statuses' }, { label: 'Technique and Gambit directory', href: '/techniques' }, { label: 'Party, Gear and Gambits', href: '/systems/party-preparation' }, { label: 'Research', href: '/systems/research' }, { label: 'Equipment', href: '/equipment' }, { label: 'All systems', href: '/systems' }]} />
  </SiteFrame>;
}
