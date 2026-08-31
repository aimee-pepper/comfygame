import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

export function generateStaticParams() { return content.resources.map(resource => ({ slug: resource.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params; const resource = content.resources.find(entry => entry.slug === slug);
  return resource ? { title: resource.name, description: resource.summary } : {};
}

export default async function ResourceDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const resource = content.resources.find(entry => entry.slug === slug); if (!resource) notFound();
  return <SiteFrame sidebar><div className="entity-heading"><PixelImage src={resource.assetURL} alt={`${resource.name} inventory icon`} size={96} /><PageIntro eyebrow={`${resource.tradeBand} resource`} title={resource.name} summary={resource.summary} /></div>
    <section className="article-section"><h2>Where it tends to appear</h2><p><strong>Primary pressure:</strong> {resource.drivenBy}</p><div className="two-column"><div><h3>Required conditions</h3><ul>{resource.requires.map(line => <li key={line}>{line}</li>)}</ul></div><div><h3>Conditions that help</h3><ul>{resource.favours.map(line => <li key={line}>{line}</li>)}</ul></div></div></section>
    <section className="article-section"><h2>Current uses</h2><ul>{resource.currentUses.map(line => <li key={line}>{line}</li>)}</ul></section>
    <nav className="next-links"><Link href="/resources">Back to all resources</Link><Link href="/systems/crafting">Crafting and materials</Link></nav>
  </SiteFrame>;
}
