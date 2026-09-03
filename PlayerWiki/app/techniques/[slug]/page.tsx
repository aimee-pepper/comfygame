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
    <section className="article-section"><h2>How to use it</h2><dl className="fact-grid"><div><dt>How it is learned</dt><dd>{reference.source}</dd></div><div><dt>Who can use it</dt><dd>{reference.eligible}</dd></div><div><dt>When it activates</dt><dd>{reference.trigger}</dd></div><div><dt>Target</dt><dd>{reference.target}</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>What it does</h2><p>{reference.result}</p></div><div><h2>Costs, cooldowns, and limits</h2><p>{reference.limits}</p></div></section>
    <section className="article-section note-card"><h2>Check the encounter before choosing</h2><p>The combat card or Gambit editor shows whether this action is ready and which targets are still valid. If the target changes, the technique is cooling down, or the Gambit is incomplete, the game will not silently use a different action.</p></section>
    <RelatedGuides links={[{ label: 'All techniques and Gambits', href: '/techniques' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Party and Gear', href: '/systems/party-preparation' }, { label: 'Equipment', href: '/equipment' }, { label: 'Research', href: '/research' }]} />
  </SiteFrame>;
}
