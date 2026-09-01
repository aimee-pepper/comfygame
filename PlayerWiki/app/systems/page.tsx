import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { playerStartGuides, systemGuideCategories } from '@/lib/system-guides';

export default function SystemsHub() {
  const partyMember = content.travellers.find((person) => person.assetURL);
  const weapon = content.items.find((item) => item.gear?.slot === 'weapon' && item.assetURL);
  const station = content.stations.find((place) => place.id === 'apothecary');
  const resource = content.resources.find((item) => item.assetURL);
  const visuals = {
    journey: {
      visualURL: content.writingAssetURL,
      visualAlt: 'Writing Desk parchment',
    },
    combat: {
      visualURL: weapon?.assetURL ?? partyMember?.assetURL ?? null,
      visualAlt: weapon ? `${weapon.name} icon` : partyMember ? `${partyMember.name} character visual` : 'Combat reference',
    },
    village: {
      visualURL: station?.assetURL ?? resource?.assetURL ?? null,
      visualAlt: station?.assetURL ? `${station.name} building visual` : resource ? `${resource.name} inventory icon` : 'Crafting reference',
    },
  };

  return <SiteFrame sidebar><PageIntro eyebrow="Player guides" title="Systems" summary="Choose a guide by the question you have right now: how to begin, what to prepare, where to craft, or which Village screen and reference table you need." />
    <section className="article-section note-card"><h2>Begin the current route</h2><nav aria-label="Starting guides">{playerStartGuides.map((guide) => <Link href={guide.href} key={guide.href}>{guide.label}</Link>)}</nav></section>
    <section className="article-section note-card"><h2>Field references</h2><p>When a revealed world feature or encounter needs a name, open the current profile first; neither directory marks it as discovered in your own campaign.</p><nav aria-label="Field reference directories"><Link href="/bestiary">Bestiary profiles</Link><Link href="/sites">Site directory</Link><Link href="/resources">Resources</Link></nav></section>
    <section className="article-section systems-hub-grid">{systemGuideCategories.map((category) => { const visual = visuals[category.id]; return <article className="system-hub-card" key={category.id}>{visual.visualURL && <PixelImage src={visual.visualURL} alt={visual.visualAlt} size={64} />}<div><h2>{category.label}</h2><p>{category.summary}</p><nav aria-label={`${category.label} guides`}>{category.guides.map((guide) => <Link href={guide.href} key={guide.href}>{guide.label}</Link>)}</nav></div></article>; })}</section>
  </SiteFrame>;
}
