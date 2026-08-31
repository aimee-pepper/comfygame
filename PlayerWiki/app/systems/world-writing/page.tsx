import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

const steps = [
  ['1', 'Choose a hand', 'Select the writing tool whose marks and capabilities you want to work with.'],
  ['2', 'Choose ink', 'Choose the prepared or open ink treatment before laying out the request.'],
  ['3', 'Place and connect', 'Place Subjects, connect Focuses, then narrow them with Modifiers. Compounds hold complete statements in less space.'],
  ['4', 'Review and Bind', 'Read the World preview, correct the Page if needed, then Bind to create the expedition world.'],
];

export default function WorldWriting() {
  return <SiteFrame sidebar><PageIntro eyebrow="System guide" title="World Writing" summary="A Page is a request, not a tile-by-tile map. You arrange Sigils to influence the pressures and qualities of the world that Binding creates." />
    <figure className="feature-figure">{content.writingAssetURL && <img src={content.writingAssetURL} alt="The parchment used by the Writing Desk" />}<figcaption>The Writing Desk keeps the Page, writing tools, vocabulary, and World preview in one workspace.</figcaption></figure>
    <section className="article-section"><h2>Write a Page in this order</h2><div className="step-grid">{steps.map(([number, title, text]) => <article key={number}><span>{number}</span><h3>{title}</h3><p>{text}</p></article>)}</div></section>
    <section className="article-section"><h2>The four building blocks</h2><dl className="definition-grid"><div><dt>Subject</dt><dd>What the request is about.</dd></div><div><dt>Focus</dt><dd>A linked Sigil asking the world to change its Subject.</dd></div><div><dt>Modifier</dt><dd>Changes how a connected Focus is applied.</dd></div><div><dt>Compound</dt><dd>A reusable Sigil holding one complete statement in a smaller footprint.</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>What the preview tells you</h2><p>The World preview describes likely pressures and broad qualities without promising exact terrain, sites, creatures, or resources. Use it to compare the direction of the Page before spending the Bind.</p></div><div className="note-card"><h3>Editing is not Binding</h3><p>Ordinary Page editing lets you revise the request. The expedition begins only after an accepted Bind creates the world and the arrival sequence completes.</p></div></section>
    <nav className="next-links"><Link href="/systems/exploration">Next: Exploration</Link><Link href="/glossary">Writing terms</Link></nav>
  </SiteFrame>;
}
