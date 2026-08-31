import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

export default function SystemsHub() {
  const partyMember = content.travellers.find((person) => person.assetURL);
  const weapon = content.items.find((item) => item.gear?.slot === 'weapon' && item.assetURL);
  const station = content.stations.find((place) => place.id === 'apothecary');
  const resource = content.resources.find((item) => item.assetURL);
  const groups = [
    {
      title: 'Journey and worlds',
      summary: 'Start a campaign, write the next world, then learn what remains visible and useful once you enter it.',
      visualURL: content.writingAssetURL,
      visualAlt: 'Writing Desk parchment',
      links: [['Getting started', '/getting-started'], ['Your current journey', '/journey'], ['World Writing', '/systems/world-writing'], ['Exploration', '/systems/exploration'], ['Sites and hazards', '/systems/sites-hazards'], ['Animals and companionship', '/systems/animals-companionship'], ['Research', '/systems/research']],
    },
    {
      title: 'Combat and preparation',
      summary: 'Read the encounter, prepare the travelling party, then compare the gear and supplies available before you depart.',
      visualURL: weapon?.assetURL ?? partyMember?.assetURL ?? null,
      visualAlt: weapon ? `${weapon.name} icon` : partyMember ? `${partyMember.name} character visual` : 'Combat reference',
      links: [['Combat', '/systems/combat'], ['Party, Gear and Gambits', '/systems/party-preparation'], ['Equipment and material effects', '/systems/equipment-materials'], ['Inventory and custody', '/systems/inventory-custody'], ['Field supplies', '/systems/field-supplies'], ['Equipment', '/equipment'], ['Consumables', '/consumables']],
    },
    {
      title: 'Crafting and materials',
      summary: 'Follow a material from its world source to a current recipe, station, and finished item.',
      visualURL: station?.assetURL ?? resource?.assetURL ?? null,
      visualAlt: station?.assetURL ? `${station.name} building visual` : resource ? `${resource.name} inventory icon` : 'Crafting reference',
      links: [['Crafting basics', '/systems/crafting'], ['Economy and exchange', '/systems/economy-exchange'], ['Crafting systems', '/crafting'], ['Resources', '/resources']],
    },
    {
      title: 'Village services',
      summary: 'Use the everyday Village screens to manage storage, party placement, refinement, records, and preparation.',
      visualURL: content.stations.find((place) => place.id === 'storehouse')?.assetURL ?? null,
      visualAlt: 'Storehouse building visual',
      links: [['All services', '/services'], ['Places and stations', '/places'], ['People', '/people']],
    },
    {
      title: 'Reference',
      summary: 'Open the concise tables when you need the exact current item, resource, curio, or term rather than a broader guide.',
      visualURL: resource?.assetURL ?? null,
      visualAlt: resource ? `${resource.name} inventory icon` : 'Resource reference',
      links: [['Knowledge and records', '/systems/knowledge-records'], ['Resources', '/resources'], ['Equipment', '/equipment'], ['Curios and key items', '/curios'], ['Glossary', '/glossary']],
    },
  ];

  return <SiteFrame sidebar><PageIntro eyebrow="Player guides" title="Systems" summary="Choose a guide by the question you have right now: how to begin, what to prepare, where to craft, or which Village screen and reference table you need." />
    <section className="article-section systems-hub-grid">{groups.map((group) => <article className="system-hub-card" key={group.title}>{group.visualURL && <PixelImage src={group.visualURL} alt={group.visualAlt} size={64} />}<div><h2>{group.title}</h2><p>{group.summary}</p><nav aria-label={`${group.title} guides`}>{group.links.map(([label, href]) => <Link href={href} key={href}>{label}</Link>)}</nav></div></article>)}</section>
  </SiteFrame>;
}
