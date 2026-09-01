import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';

function constructionCost(station: (typeof content.stations)[number]) {
  if (!station.buildCost.length) return 'No current construction cost is published.';
  return station.buildCost.map((cost, index) => {
    const id = cost.id ?? cost.resource ?? cost.resourceID;
    const resource = id ? content.resources.find((entry) => entry.id === id) : null;
    const quantity = cost.quantity ?? cost.amount ?? '?';
    return <span key={`${station.id}-${id}-${index}`}>{index ? ', ' : ''}{quantity} {resource ? <Link href={`/resources/${resource.slug}`}>{resource.name}</Link> : humanize(id)}</span>;
  });
}

export default function JourneyGuide() {
  const startingPlaces = content.stations.filter((station) => station.unlockedAtStart);
  const buildablePlaces = content.stations.filter((station) => !station.unlockedAtStart);
  const firstGear = content.items.find((item) => item.gear && item.assetURL);
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Current journey' }]} />
      <PageIntro
        eyebrow="Player guide"
        title="Your current journey"
        summary="Use this guide to connect the systems that are available now: prepare in the Village, write and Bind a world, explore it, return with what you recovered, then choose the next current build, service, recipe, or Research node."
      />
      <section className="article-section">
        <h2>The journey that is available now</h2>
        <ol className="numbered-guide">
          <li><span><strong>Prepare at home</strong><p>Review the current party, stored supplies, Field Kit, and Village work before leaving. The places available from the start are listed below.</p></span></li>
          <li><span><strong>Write, review, and Bind</strong><p>At the Writing Desk, choose a hand and ink, place and connect the Page, read the World preview, then Bind the Page when it is ready.</p></span></li>
          <li><span><strong>Enter and explore the generated world</strong><p>Arrival begins on the entry portal. Look at unfamiliar places, gather what you can carry, search revealed sites, and return through a valid exit when you are ready.</p></span></li>
          <li><span><strong>Review the return at the Village</strong><p>Use the expedition result to review what came back, resolve any capacity decision, then prepare the next trip or put returned resources toward a current construction, recipe, or Research cost.</p></span></li>
        </ol>
      </section>
      <section className="article-section journey-strip"><Link href="/resources/progression"><img src={content.writingAssetURL} alt="Writing Desk parchment" /><span><strong>Current task checklist</strong><small>Move from the next Page through resources, Village work, Research, party preparation, and return.</small></span></Link><Link href="/systems/exploration"><img src={content.explorationVisuals.entryPortal} alt="Entry portal" /><span><strong>World route</strong><small>Use the entry portal and current world detail as you explore.</small></span></Link>{firstGear?.assetURL && <Link href={`/equipment/${firstGear.slug}`}><PixelImage src={firstGear.assetURL} alt={`${firstGear.name} icon`} size={58} /><span><strong>Party preparation</strong><small>Compare custody and the current slot before equipping.</small></span></Link>}</section>
      <section className="article-section two-column">
        <div>
          <h2>What this guide does not promise</h2>
          <p>It describes the routes, costs, and choices currently shown in the game. It does not prescribe a future building or Research order, and it does not promise an unavailable route.</p>
        </div>
        <div className="note-card">
          <h3>Read the current screen</h3>
          <p>For a recipe, building, or Research node, the displayed current requirements and result are the ones to use when deciding what to do next.</p>
        </div>
      </section>
      <section className="article-section">
        <h2>Available from the start</h2>
        <div className="definition-grid">
          {startingPlaces.map((station) => <div key={station.id}><h3><Link href={`/places/${station.slug}`}>{station.name}</Link></h3><p>{station.blurb}</p></div>)}
        </div>
      </section>
      <section className="article-section">
        <h2>Current Village construction</h2>
        <p>Each row is a current building with its published construction requirements. Open the place page to see its current service and any current crafting it owns.</p>
        <div className="table-wrap data-table"><table><thead><tr><th>Building</th><th>Construction requirements</th><th>Current use</th></tr></thead><tbody>
          {buildablePlaces.map((station) => <tr key={station.id}><td><Link href={`/places/${station.slug}`}>{station.name}</Link></td><td>{constructionCost(station)}</td><td>{station.blurb}</td></tr>)}
        </tbody></table></div>
      </section>
      <section className="article-section">
        <h2>Services, crafting, and Research</h2>
        <div className="definition-grid">
          <div><h3><Link href="/services">Village services</Link></h3><p>Use the current service screens for storage, party preparation, trade, refinement, records, and other everyday Village work.</p></div>
          <div><h3><Link href="/crafting">Crafting systems</Link></h3><p>Open a current station guide to compare its published inputs, material choices, output, and access facts before you commit a recipe.</p></div>
          <div><h3><Link href="/research">Research</Link></h3><p>Open the current Research node to compare listed prerequisites, base cost, and current result. Earlier listed upgrades are required when the node says so; this guide does not predict an order beyond those current requirements.</p></div>
        </div>
      </section>
      <RelatedGuides links={[
        { label: 'Getting started', href: '/getting-started' },
        { label: 'Action reference', href: '/actions' },
        { label: 'Current progression checklist', href: '/resources/progression' },
        { label: 'World Writing', href: '/systems/world-writing' },
        { label: 'Exploration', href: '/systems/exploration' },
        { label: 'Village services', href: '/services' },
        { label: 'Places and stations', href: '/places' },
        { label: 'Crafting systems', href: '/crafting' },
        { label: 'Research guide', href: '/systems/research' },
      ]} />
    </SiteFrame>
  );
}
