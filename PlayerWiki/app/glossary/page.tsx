import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

export default function GlossaryPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Glossary" summary="Plain-language definitions for Bookbinder's recurring terms, grouped by the part of the game where you encounter them." />
    {[...new Set(content.terminology.map(term => term.domain))].map(domain => <section className="article-section" key={domain}><h2>{domain}</h2><dl className="definition-grid">{content.terminology.filter(term => term.domain === domain).map(term => <div id={term.slug} key={term.id}><dt><strong>{term.name}</strong></dt><dd>{term.summary}{term.aliases.length ? <small> Also called: {term.aliases.join(', ')}.</small> : null}</dd></div>)}</dl></section>)}
  </SiteFrame>;
}
