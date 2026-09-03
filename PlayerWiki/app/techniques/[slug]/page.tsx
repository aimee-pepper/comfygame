import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { techniqueForSlug, techniqueReferences } from '@/lib/technique-reference';

export function generateStaticParams() { return techniqueReferences.map((reference) => ({ slug: reference.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params; const reference = techniqueForSlug(slug); return reference ? { title: reference.name, description: reference.result } : {};
}

export default async function TechniqueDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const reference = techniqueForSlug(slug); if (!reference) notFound();
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Techniques and Gambits', href: '/techniques' }, { label: reference.name }]} />
    <PageIntro eyebrow={reference.group} title={reference.name} summary={reference.result} />
    <section className="article-section"><h2>Current use</h2><dl className="fact-grid"><div><dt>Source or grant</dt><dd>{reference.source}</dd></div><div><dt>Who can use it</dt><dd>{reference.eligible}</dd></div><div><dt>Trigger</dt><dd>{reference.trigger}</dd></div><div><dt>Target</dt><dd>{reference.target}</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>Exact current result</h2><p>{reference.result}</p></div><div><h2>Costs, cooldowns, and limits</h2><p>{reference.limits}</p></div></section>
    <section className="article-section note-card"><h2>Use the current card or rule</h2><p>The mounted combat card or Gambit editor is the final source for this action’s current readiness and target. A changed target, cooling technique, or incomplete rule does not commit a substitute action.</p></section>
    <RelatedGuides links={[{ label: 'All techniques and Gambits', href: '/techniques' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Party and Gear', href: '/systems/party-preparation' }, { label: 'Equipment', href: '/equipment' }, { label: 'Research', href: '/research' }]} />
  </SiteFrame>;
}
