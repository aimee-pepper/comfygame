import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { actionForSlug, actionReferences } from '@/lib/action-reference';

export function generateStaticParams() { return actionReferences.map((action) => ({ slug: action.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> { const { slug } = await params; const action = actionForSlug(slug); return action ? { title: action.name, description: action.change } : {}; }

export default async function ActionDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const action = actionForSlug(slug); if (!action) notFound();
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Action reference', href: '/actions' }, { label: action.name }]} />
    <PageIntro eyebrow={action.group} title={action.name} summary={action.change} />
    <section className="article-section"><h2>Current action facts</h2><dl className="fact-grid"><div><dt>Surface</dt><dd>{action.surface}</dd></div><div><dt>Available when</dt><dd>{action.availability}</dd></div><div><dt>Committed change</dt><dd>{action.change}</dd></div><div><dt>Cost</dt><dd>{action.cost}</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>What the result keeps</h2><p>{action.persistence}</p></div><div><h2>When it cannot complete</h2><p>{action.unavailable}</p></div></section>
    <RelatedGuides links={[{ label: 'All actions', href: '/actions' }, ...action.related, { label: 'Getting started', href: '/getting-started' }, { label: 'Journey', href: '/journey' }]} />
  </SiteFrame>;
}
