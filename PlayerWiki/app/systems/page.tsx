import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { playerStartGuides, systemGuideCategories } from '@/lib/system-guides';

export default function SystemsHub() {
  const partyMember = content.travellers.find((person) => person.assetURL);
  const weapon = content.items.find((item) => item.gear?.slot === 'weapon' && item.assetURL);
  const station = content.stations.find((place) => place.id === 'apothecary');
  const library = content.stations.find((place) => place.id === 'library');
  const resource = content.resources.find((item) => item.assetURL);
  const visuals = {
    worlds: {
      visualURL: content.writingAssetURL,
      visualAlt: 'Writing Desk parchment',
    },
    characters: {
      visualURL: weapon?.assetURL ?? partyMember?.assetURL ?? null,
      visualAlt: weapon ? `${weapon.name} icon` : partyMember ? `${partyMember.name} character visual` : 'Combat reference',
    },
    village: {
      visualURL: station?.assetURL ?? resource?.assetURL ?? null,
      visualAlt: station?.assetURL ? `${station.name} building visual` : resource ? `${resource.name} inventory icon` : 'Village reference',
    },
    crafting: {
      visualURL: resource?.assetURL ?? weapon?.assetURL ?? null,
      visualAlt: resource ? `${resource.name} inventory icon` : weapon ? `${weapon.name} icon` : 'Crafting reference',
    },
    knowledge: {
      visualURL: library?.assetURL ?? library?.contextAssetURL ?? null,
      visualAlt: library?.assetURL ? `${library.name} building visual` : 'Library and records reference',
    },
  };

  return <SiteFrame sidebar><PageIntro eyebrow="Player guides" title="Systems" summary="Choose a guide by the question you have right now: how to begin, what to prepare, where to craft, or which Village screen and reference table you need." />
    <section className="article-section note-card"><h2>Begin the current route</h2><nav aria-label="Starting guides">{playerStartGuides.map((guide) => <Link href={guide.href} key={guide.href}>{guide.label}</Link>)}</nav></section>
    <section className="article-section note-card"><h2>Browse the Wiki by subject</h2><p>Each subject has one category page with a compact index, a useful comparison, and its shared rules. Open a linked entry for the complete details about that one thing.</p><div className="definition-grid"><div><h3>Worlds</h3><nav aria-label="World directories"><Link href="/world">World conditions</Link><Link href="/terrain">Terrain</Link><Link href="/flora">Flora</Link><Link href="/sites">Sites and hazards</Link><Link href="/bestiary">Bestiary</Link></nav></div><div><h3>Characters</h3><nav aria-label="Character directories"><Link href="/people">People</Link><Link href="/techniques">Techniques and Gambits</Link><Link href="/statuses">Conditions and effects</Link></nav></div><div><h3>Village</h3><nav aria-label="Village directory"><Link href="/village">Village buildings, services, and construction</Link></nav></div><div><h3>Crafting and items</h3><nav aria-label="Crafting and item directories"><Link href="/crafting">Crafting</Link><Link href="/resources">Resources</Link><Link href="/equipment">Equipment</Link><Link href="/consumables">Consumables and Field Kit</Link><Link href="/curios">Curios</Link><Link href="/trading">Economy and exchange</Link><Link href="/recycling">Recycler</Link></nav></div><div><h3>Knowledge</h3><nav aria-label="Knowledge directories"><Link href="/research">Research</Link><Link href="/buildings/library">Library and records</Link></nav></div></div></section>
    <section className="article-section systems-hub-grid">{systemGuideCategories.map((category) => { const visual = visuals[category.id]; return <article className="system-hub-card" key={category.id}>{visual.visualURL && <PixelImage src={visual.visualURL} alt={visual.visualAlt} size={64} />}<div><h2>{category.label}</h2><p>{category.summary}</p><nav aria-label={`${category.label} guides`}>{category.guides.map((guide) => <Link href={guide.href} key={guide.href}>{guide.label}</Link>)}</nav></div></article>; })}</section>
  </SiteFrame>;
}
