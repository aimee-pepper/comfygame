import Link from '@/components/wiki-link';
import {
  BookOpenText,
  Compass,
  Hammer,
  Map,
  PackageOpen,
  Shield,
  Sparkles,
  Users,
  LibraryBig,
} from 'lucide-react';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

const sections = [
  { href: '/getting-started', label: 'Getting started', detail: 'Begin a campaign and understand the core loop.', icon: BookOpenText },
  { href: '/systems/world-writing', label: 'World Writing', detail: 'Choose a hand and ink, place glyphs, connect them, and bind a world.', icon: Sparkles },
  { href: '/systems/exploration', label: 'Exploration', detail: 'Travel through unstable worlds, inspect terrain, and return with what you find.', icon: Compass },
  { href: '/systems/combat', label: 'Combat', detail: 'Read encounters, choose actions, and manage your party.', icon: Shield },
  { href: '/crafting', label: 'Crafting', detail: 'Turn resources into supplies, equipment, and village improvements.', icon: Hammer },
  { href: '/village', label: 'Village', detail: 'Find places, services, construction costs, and the people who work there.', icon: Map },
];

const resources = [
  ['Rubble', 'Common', 'Substrate-heavy worlds', 'Building and refinery work'],
  ['Clay', 'Common', 'Substrate-heavy worlds', 'Construction and prepared materials'],
  ['Iron Ore', 'Common', 'Rocky world tiles', 'Metal equipment and station work'],
  ['Copper', 'Uncommon', 'Mineral-rich worlds', 'Equipment and conductive parts'],
];

export default function Home() {
  const firstSupply = content.items.find((item) => item.consumable && item.assetURL);

  return (
    <SiteFrame>
        <section className="welcome" aria-labelledby="welcome-title">
          <div>
            <p className="eyebrow">A practical guide to the game</p>
            <h1 id="welcome-title">Find what you need to play Bookbinder.</h1>
            <p className="lede">Learn a system, compare equipment, find a resource, or look up a person without wading through development notes.</p>
            <div className="welcome-actions">
              <Link className="primary-action" href="/getting-started">Start here</Link>
              <Link className="secondary-action" href="/systems/world-writing">How World Writing works</Link>
            </div>
          </div>
          <aside className="quick-reference" aria-label="Quick reference">
            <span><PackageOpen size={18} /> Browse the game</span>
            <Link href="/resources">Resources</Link>
            <Link href="/equipment">Equipment</Link>
            <Link href="/consumables">Consumables</Link>
            <Link href="/curios">Curios & key items</Link>
            <Link href="/people"><Users size={16} /> People</Link>
          </aside>
        </section>

        <section className="page-section note-card">
          <h2>Decisions recorded · 4 September</h2>
          <p>Stone starter tools, simpler first crafts, Village progression, exploration, recipe tracking, colour, and the Peerless proposal. Current behavior and future changes are clearly separated.</p>
          <p><Link href="/references/design-decisions-september-4">Read the decisions</Link> · <Link href="/references/aimee-homework">Aimee Homework</Link></p>
        </section>

        <section className="page-section journey-section" aria-labelledby="journey-heading">
          <div className="section-heading"><div><p className="eyebrow">The first journey</p><h2 id="journey-heading">Prepare, write, and step through</h2></div><Link href="/getting-started">Read the full first-trip guide</Link></div>
          <div className="journey-strip">
            <Link href="/systems/world-writing"><img src={content.writingAssetURL} alt="Writing Desk parchment" /><span><strong>Write a Page</strong><small>Use the Writing Desk to review, shape, and Bind the next world.</small></span></Link>
            <Link href="/systems/exploration"><img src={content.explorationVisuals.entryPortal} alt="Entry portal" /><span><strong>Enter the world</strong><small>The entry portal stays on the map as your way home during the expedition.</small></span></Link>
            {firstSupply && <Link href={`/items/${firstSupply.slug}`}><PixelImage src={firstSupply.assetURL} alt={`${firstSupply.name} icon`} size={58} /><span><strong>Carry a supply</strong><small>Open an item entry to understand its exact use before the field.</small></span></Link>}
          </div>
        </section>

        <section className="page-section" aria-labelledby="browse-heading">
          <div className="section-heading">
            <div><p className="eyebrow">Browse by task</p><h2 id="browse-heading">What are you trying to do?</h2></div>
          </div>
          <div className="topic-grid">
            {sections.map(({ href, label, detail, icon: Icon }) => (
              <Link className="topic-card" href={href} key={href}>
                <Icon aria-hidden="true" />
                <span><strong>{label}</strong><small>{detail}</small></span>
              </Link>
            ))}
          </div>
        </section>

        <section className="page-section reference-preview" aria-labelledby="resource-heading">
          <div className="section-heading">
            <div><p className="eyebrow">Reference at a glance</p><h2 id="resource-heading">Common resources</h2></div>
            <Link href="/resources">See all resources</Link>
          </div>
          <div className="table-wrap">
            <table>
              <thead><tr><th>Resource</th><th>Current world frequency</th><th>Mostly found</th><th>Useful for</th></tr></thead>
              <tbody>
                {resources.map(([name, rarity, found, use]) => {
                  const resource = content.resources.find((entry) => entry.name === name);
                  return <tr key={name}><td><Link href={resource ? `/resources/${resource.slug}` : '/resources'}>{name}</Link></td><td>{rarity}</td><td>{found}</td><td>{use}</td></tr>;
                })}
              </tbody>
            </table>
          </div>
        </section>

        <section className="page-section" aria-labelledby="review-references-heading">
          <div className="section-heading">
            <div><p className="eyebrow">Project reference</p><h2 id="review-references-heading">Aimee Reference</h2></div>
            <Link href="/references">Open Aimee Reference</Link>
          </div>
          <div className="topic-grid">
            <Link className="topic-card" href="/references/world-splash-assets">
              <LibraryBig aria-hidden="true" />
              <span><strong>World Splash Asset Inventory</strong><small>Open the organized final-parallax inventory, completeness audit, missing world coverage, and prescribed expansion.</small></span>
            </Link>
            <Link className="topic-card" href="/references">
              <LibraryBig aria-hidden="true" />
              <span><strong>Resource, crafting, and world plans</strong><small>Open the system directories and incremental implementation roadmap without combining every subject on one page.</small></span>
            </Link>
          </div>
        </section>

        <section className="page-section" aria-labelledby="changing-heading">
          <div className="section-heading">
            <div><p className="eyebrow">Clear, honest guidance</p><h2 id="changing-heading">Playable now—and what is changing</h2></div>
            <Link href="/guide-status">Open the status guide</Link>
          </div>
          <div className="topic-grid">
            <Link className="topic-card" href="/resources#loot-and-custody">
              <PackageOpen aria-hidden="true" />
              <span><strong>Resources, loot &amp; materials</strong><small>Find resource entries, expedition returns, storage, quality, and the intended physical-material overhaul in one guide.</small></span>
            </Link>
          </div>
        </section>
    </SiteFrame>
  );
}
