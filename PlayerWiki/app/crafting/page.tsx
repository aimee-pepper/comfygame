import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { craftingSystems } from '@/lib/crafting';
import { content } from '@/lib/content';
import { craftingFamilyStatus } from '@/lib/player-guide-status';
import { materialIdentityHierarchy, materialPropertyProblems, materialScoreBoundary, qualityRules } from '@/lib/crafting-overview';

const systemGroups = [
  {
    title: 'Preparations and processing',
    summary: 'Remedies, refined Essence, prepared ink, and distilled or fitted worldwork components.',
    slugs: ['apothecary', 'refinery', 'writing-ink', 'distillery', 'channelworks'],
  },
  {
    title: 'Weapons, clothing, and protection',
    summary: 'Each maker keeps its own patterns, material sockets, finished results, and refitting rules.',
    slugs: ['blacksmith', 'tannery', 'bowyer', 'weaponsmith', 'armoury'],
  },
  {
    title: 'Expedition tools and worldwork',
    summary: 'Permanent instruments and portable constructions that support exploration and realm keeping.',
    slugs: ['instruments', 'anchorage'],
  },
] as const;

function systemFor(slug: string) {
  return craftingSystems.find((system) => system.slug === slug);
}

function statusFor(slug: string) {
  return craftingFamilyStatus.find((entry) => entry.slug === slug);
}

export default function CraftingSystemsPage() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Crafting' }]} />
    <PageIntro
      eyebrow="Production directory"
      title="Crafting systems"
      summary="Choose one station or production family. Every system now has its own page for access, current recipes, intended ingredient rules, outputs, refusals, and related resources."
    />
    <DirectoryIndex label="Browse crafting systems" entries={systemGroups.flatMap((group) => group.slugs).flatMap((slug) => { const system = systemFor(slug); if (!system) return []; const station = content.stations.find((entry) => entry.id === system.stationID); return [{ href: `/crafting/${slug}`, name: system.name, imageURL: station?.assetURL, imageAlt: station ? `${station.name} building visual` : undefined }]; })} />

    <DirectoryDetailsIntro title="Compare crafting families" summary="The cards below give each family’s purpose and implementation status. Open one system for its complete current recipes and accepted intended design." />

    {systemGroups.map((group) => <section className="article-section" key={group.title}>
      <h2>{group.title}</h2>
      <p>{group.summary}</p>
      <div className="status-card-grid">
        {group.slugs.map((slug) => {
          const system = systemFor(slug);
          const status = statusFor(slug);
          if (!system) return null;
          const station = content.stations.find((entry) => entry.id === system.stationID);
          return <article className="status-card crafting-system-card" key={slug}>
            <div className="crafting-reachability-heading">
              {station?.assetURL && <PixelImage src={station.assetURL} alt={`${station.name} building visual`} size={48} />}
              <div>
                {status && <p className="status-pill">{status.status}</p>}
                <h3><Link href={`/crafting/${slug}`}>{system.name}</Link></h3>
              </div>
            </div>
            <p>{system.summary}</p>
            {station && <p><Link href={`/buildings/${station.slug}`}>Open {station.name}</Link></p>}
            <p><Link href={`/crafting/${slug}`}>Open the complete {system.name} guide</Link></p>
          </article>;
        })}
      </div>
    </section>)}

    <section className="article-section"><h2>Current game and intended recipe system</h2><TruthPair current="Current makers combine counted resources, exact source-bearing samples, fixed costs, and hidden hardness, density, insulation, flexibility, lustre, or reactivity thresholds. Each station page lists its exact live rule." accepted="Recipes use static ingredients plus visible broad, specific, or precise physical categories. The player selects a physical type or subtype and Poor, Common, Rare, or Exceptional quality; the preview shows direct contributions to real item statistics." acceptedLabel="Intended design" /></section>
    <section className="article-section"><h2>How recipes name ingredients</h2><p>A recipe can combine fixed ingredients with one or more material choices. A fixed ingredient names one exact resource, such as Resin. A category ingredient accepts any owned material from its displayed broad category, type, or subtype. A recipe narrows a choice only when the physical job genuinely requires it.</p><div className="table-wrap"><table><thead><tr><th>Ingredient scope</th><th>Example</th><th>Recipe meaning</th></tr></thead><tbody>{materialIdentityHierarchy.map(([level, example, use]) => <tr key={level}><td><strong>{level}</strong></td><td>{example}</td><td>{use}</td></tr>)}</tbody></table></div><ul className="compact-list"><li>The picker shows only compatible owned stacks.</li><li>The player chooses the exact subtype, quality, and quantity when more than one valid option exists.</li><li>A recipe never silently spends a higher quality than the one confirmed.</li><li>Species history can remain visible without turning every species into a separate recipe ingredient.</li></ul></section>
    <section className="article-section"><h2>Properties affect the result, not eligibility</h2><p>Several current recipes accept an object merely because an internal score crosses a threshold. The intended system keeps all six numerical properties and uses them to calculate concrete finished-item statistics. The recipe itself asks for a recognizable physical material, type, or subtype.</p><div className="table-wrap"><table><thead><tr><th>Property</th><th>What it does now</th><th>Intended job</th></tr></thead><tbody>{materialPropertyProblems.map(([name, current, intended]) => <tr key={name}><td><strong>{name}</strong></td><td>{current}</td><td>{intended}</td></tr>)}</tbody></table></div><TruthPair current={materialScoreBoundary.currentGrade} accepted={materialScoreBoundary.intended} acceptedLabel="Intended design" /></section>
    <section className="article-section two-column"><div><h2>Quality is a deliberate choice</h2><ul className="compact-list">{qualityRules.map(([band, behavior]) => <li key={band}><strong>{band}:</strong> {behavior}</li>)}</ul><p><Link href="/systems/inventory-custody">Read quality, stacks, and custody</Link></p></div><div><h2>Read the complete station page</h2><p>Every station page owns its recipes, access, exact inputs, outputs, limitations, refusals, current behavior, and intended changes. The directory above is only the concise comparison layer.</p><p><Link href="/resources">Browse materials and acquisition</Link></p></div></section>
    <section className="article-section"><h2>Preview before making</h2><div className="step-grid"><article><span>1</span><h3>Choose a revealed station</h3><p>The station, known recipe or schematic, and its access rule must all be available before its current preview can be used.</p></article><article><span>2</span><h3>Keep cost forms distinct</h3><p>Stored resources, exact materials, Essence Crystals, and Motes are different costs. One cannot silently replace another.</p></article><article><span>3</span><h3>Commit the quoted result</h3><p>The station rechecks ingredients, selected materials, recipe, and legal Storehouse or Waiting destination. A changed quote needs a fresh preview.</p></article></div></section>

    <section className="article-section">
      <h2>Reuse and adjacent services</h2>
      <div className="status-card-grid">
        <article className="status-card"><h3><Link href="/village">Village buildings</Link></h3><p>Check which station is currently available, what opens its foundation, and which services are scheduled rather than live.</p></article>
        <article className="status-card"><h3><Link href="/recycling">Recycler</Link></h3><p>Dismantle an eligible finished item through its own preview, custody, yield, and intended material-return rules.</p></article>
        <article className="status-card"><h3><Link href="/research">Research</Link></h3><p>Study capabilities and recipe-related knowledge through its own prerequisites, costs, and permanent progression.</p></article>
        <article className="status-card"><h3><Link href="/trading">Trading Post</Link></h3><p>Buy and sell exact eligible holdings through its own price, stock, quantity, quality, and custody rules.</p></article>
      </div>
    </section>
    <RelatedGuides links={[{ label: 'Resources', href: '/resources' }, { label: 'Inventory and custody', href: '/systems/inventory-custody' }, { label: 'Equipment', href: '/equipment' }, { label: 'Current progression', href: '/resources/progression' }, { label: 'Village', href: '/village' }, { label: 'Worlds and harvesting', href: '/world' }]} />
  </SiteFrame>;
}
