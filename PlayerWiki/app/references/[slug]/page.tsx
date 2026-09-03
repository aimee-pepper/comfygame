import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import Link from '@/components/wiki-link';
import { GuideBreadcrumbs } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { designReferenceFor, designReferences } from '@/lib/design-references';

export function generateStaticParams() {
  return designReferences.map((reference) => ({ slug: reference.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const reference = designReferenceFor(slug);
  return reference
    ? { title: reference.title, description: reference.summary }
    : {};
}

export default async function DesignReferencePage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const reference = designReferenceFor(slug);
  if (!reference) notFound();
  const index = designReferences.findIndex((entry) => entry.slug === slug);
  const previous = index > 0 ? designReferences[index - 1] : null;
  const next = index < designReferences.length - 1 ? designReferences[index + 1] : null;

  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Aimee Reference', href: '/references' }, { label: reference.title }]} />
    <PageIntro eyebrow="Game Design reference" title={reference.title} summary={reference.summary} />
    <article className="article-section markdown-reference">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          h1: () => null,
          table: ({ node: _node, ...props }) => <div className="table-wrap"><table {...props} /></div>,
          blockquote: ({ node: _node, ...props }) => <blockquote className="note-card" {...props} />,
        }}
      >{reference.source}</ReactMarkdown>
    </article>
    {reference.systemLinks.length ? <section className="article-section">
      <h2>Related player-facing system pages</h2>
      <p>The complete plan is above. These links lead to the subject-specific Wiki pages when you want current gameplay and intended design compared in that system's own context.</p>
      <div className="topic-grid">
        {reference.systemLinks.map((entry) => <Link className="topic-card" href={entry.href} key={`${entry.href}-${entry.title}`}><span><strong>{entry.title}</strong><small>{entry.summary}</small></span></Link>)}
      </div>
    </section> : null}
    <nav className="next-links" aria-label="Game Design references">
      {previous ? <Link href={`/references/${previous.slug}`}>Previous: {previous.title}</Link> : <Link href="/references">All references</Link>}
      {next ? <Link href={`/references/${next.slug}`}>Next: {next.title}</Link> : <Link href="/crafting">Crafting systems</Link>}
    </nav>
  </SiteFrame>;
}
