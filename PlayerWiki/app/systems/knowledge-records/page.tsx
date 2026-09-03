import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { CanonicalPageRedirect } from '@/components/canonical-page-redirect';

export default function KnowledgeRecordsRedirect() {
  return <CanonicalPageRedirect formerTitle="Library and records guide" href="/buildings/library" label="Library and records" />;
}

function PreservedFormerKnowledgeRecordsGuide() {
  const library = content.stations.find((station) => station.id === 'library');
  const traveller = content.travellers.find((person) => person.assetURL);
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Knowledge and records' }]} />
    <PageIntro eyebrow="Current system guide" title="Knowledge and records" summary="Use the Library to read the records you have recovered, find people through their current hints, review known writing vocabulary, and compare encountered creatures without revealing entries you have not found." />
    <section className="article-section journey-strip">{library?.assetURL && <Link href="/services/library"><PixelImage src={library.assetURL} alt="Library building visual" size={64} /><span><strong>Library</strong><small>Open Diaries, People, Dictionary, Notes, and History.</small></span></Link>}{traveller?.assetURL && <Link href={`/people/${traveller.slug}`}><PixelImage src={traveller.assetURL} alt={`${traveller.name} character visual`} size={64} /><span><strong>People and their books</strong><small>Read each person’s available book pages, with location clues clearly marked.</small></span></Link>}</section>
    <section className="article-section"><h2>Library collections</h2><div className="definition-grid"><div><h3>Diaries</h3><p>Read recovered diary pages as they were written. A lesson attached to a page appears with it.</p></div><div><h3>People</h3><p>Each person page keeps all of that person’s currently available book pages together. Location clues are clearly marked so you can avoid spoilers.</p></div><div><h3>Dictionary</h3><p>Review known Sigils and Compounds. Unknown meanings remain unknown until they are learned.</p></div><div><h3>Notes and History</h3><p>Open recovered notes and the history of worlds you have visited. Older entries may remain listed even when their original prose is unavailable.</p></div></div><p><Link href="/services/library">Open Library collections</Link> · <Link href="/people">Browse people and their books</Link> · <Link href="/glossary">Open the glossary</Link></p></section>
    <section className="article-section two-column"><div><h2>How records become useful</h2><p>Read the exact recovered wording before acting on it. A diary page can preserve a person’s hint or an explicitly attached teaching; the Dictionary keeps the writing vocabulary you have learned; Notes and History let you revisit records already available in the Library.</p></div><div className="note-card"><h3>Research and records</h3><p>Some current diary pages point toward a Research lead. Read the named current Research node and its listed requirements before deciding what to prepare next.</p><p><Link href="/research">Open Research</Link></p></div></section>
    <section className="article-section two-column"><div><h2>Bestiary records</h2><p>The in-game Bestiary is for creatures you have encountered. The Player Wiki lists current named encounter profiles without marking one as discovered or exposing an individual specimen’s hidden traits.</p><p><Link href="/bestiary">Open Bestiary profiles</Link></p></div><div><h2>Use the right guide</h2><p>Use World Writing for Page terms, Research for unlock requirements, Sites for current field profiles, and Combat for the encounter systems around a creature record. The Library preserves the reference record rather than turning it into an automatic checklist.</p><p><Link href="/systems/world-writing">World Writing</Link> · <Link href="/systems/combat">Combat</Link> · <Link href="/sites">Site directory</Link></p></div></section>
    <RelatedGuides links={[{ label: 'Library', href: '/services/library' }, { label: 'People', href: '/people' }, { label: 'Bestiary records', href: '/bestiary' }, { label: 'Research', href: '/research' }, { label: 'World Writing', href: '/systems/world-writing' }, { label: 'Glossary', href: '/glossary' }]} />
  </SiteFrame>;
}
