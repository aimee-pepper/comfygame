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
import { craftedQualityRules, materialIdentityHierarchy, materialPropertyProblems, materialScoreBoundary, processingConversions, processingQualityRules, qualityRules, sourceLotRules } from '@/lib/crafting-overview';

const systemGroups = [
  {
    title: 'Preparations and processing',
    summary: 'Remedies, refined Essence, prepared ink, and distilled or fitted worldwork components.',
    slugs: ['apothecary', 'refinery', 'writing-ink', 'distillery', 'channelworks'],
  },
  {
    title: 'Weapons, clothing, and protection',
    summary: 'Each maker keeps their own patterns, ingredient choices, finished results, and refitting rules.',
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
      summary="Choose a station or kind of craft. Every system has its own page explaining how to open it, what you can make now, what is planned, which ingredients it uses, and where the result goes."
    />
    <DirectoryIndex label="Browse crafting systems" entries={systemGroups.flatMap((group) => group.slugs).flatMap((slug) => { const system = systemFor(slug); if (!system) return []; const station = content.stations.find((entry) => entry.id === system.stationID); return [{ href: `/crafting/${slug}`, name: system.name, imageURL: station?.assetURL, imageAlt: station ? `${station.name} building visual` : undefined }]; })} />

    <DirectoryDetailsIntro title="Compare crafting families" summary="The cards below explain what each craft is for and whether it is playable now or planned. Open one for its complete recipes and planned design." />

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

    <section className="article-section"><h2>How recipes work now and how they will change</h2><TruthPair current="Crafting currently combines counted resources, individual gathered materials, fixed costs, and hidden Hardness, Density, Insulation, Flexibility, Lustre, or Reactivity requirements. Each station page explains the rules its current recipes use." accepted="Recipes will combine fixed ingredients with clear material categories. Mined and ordinary flora ingredients use their exact plain name or subtype and quantity, with no quality choice. For creature ingredients, you will choose a physical type or subtype and a Poor, Common, Rare, or Exceptional quality; the preview will show how that choice changes the finished item’s real statistics." acceptedLabel="Intended design" /></section>
    <section className="article-section"><h2>How recipes name ingredients</h2><p>A recipe can combine fixed ingredients with one or more material choices. A fixed ingredient names one exact resource, such as Sand or Gold. A category ingredient accepts any known owned material from its displayed broad category, type, or subtype. A recipe narrows a choice only when the physical job genuinely requires it.</p><div className="table-wrap"><table><thead><tr><th>Ingredient scope</th><th>Example</th><th>Recipe meaning</th></tr></thead><tbody>{materialIdentityHierarchy.map(([level, example, use]) => <tr key={level}><td><strong>{level}</strong></td><td>{example}</td><td>{use}</td></tr>)}</tbody></table></div><ul className="compact-list"><li>The picker shows only compatible known and owned stacks; it does not spoil undiscovered species.</li><li>Mined and ordinary flora materials require only exact material/type and quantity selection.</li><li>The player chooses the exact subtype, quality, and quantity when a quality-bearing creature ingredient offers more than one valid option.</li><li>A recipe never silently spends a higher quality than the one confirmed.</li><li>Species history can remain visible without turning every species into a separate recipe ingredient.</li></ul></section>
    <section className="article-section"><h2>Properties affect the result, not eligibility</h2><p>Several current recipes accept an object merely because an internal score crosses a threshold. The intended system keeps all six numerical properties and uses them to calculate concrete finished-item statistics. The recipe itself asks for a recognizable physical material, type, or subtype.</p><div className="table-wrap"><table><thead><tr><th>Property</th><th>What it does now</th><th>Intended job</th></tr></thead><tbody>{materialPropertyProblems.map(([name, current, intended]) => <tr key={name}><td><strong>{name}</strong></td><td>{current}</td><td>{intended}</td></tr>)}</tbody></table></div><TruthPair current={materialScoreBoundary.currentGrade} accepted={materialScoreBoundary.intended} acceptedLabel="Intended design" /></section>
    <section className="article-section two-column"><div><h2>Creature quality is a deliberate choice</h2><p>Mined resources and ordinary flora materials are ungraded and have no quality choice.</p><ul className="compact-list">{qualityRules.map(([band, behavior]) => <li key={band}><strong>{band}:</strong> {behavior}</li>)}</ul><p><Link href="/systems/inventory-custody">Read quality, stacks, and storage</Link></p></div><div><h2>Read the complete station page</h2><p>Each station page brings together its recipes, access, ingredients, results, limitations, unavailable states, current behavior, and intended changes. The directory above is only the quick comparison.</p><p><Link href="/resources">Browse materials and acquisition</Link></p></div></section>
    <section className="article-section"><h2>Finished workmanship is separate from material quality</h2><p>Identity-bearing primary sockets share 70% of a finished item’s ordinary quality score and structural secondary sockets share 30%. Poor, Common, Rare, and Exceptional creature materials contribute ranks 0–3. An ungraded designated socket contributes rank 1, so a normal recipe made entirely from ungraded stock is Fine unless that exact recipe has a fixed named result. Add the weighted ranks and round half up once.</p><div className="table-wrap"><table><thead><tr><th>Rounded score</th><th>Finished name</th><th>Meaning</th></tr></thead><tbody>{craftedQualityRules.map(([score, name, meaning]) => <tr key={score}><td>{score}</td><td><strong>{name}</strong></td><td>{meaning}</td></tr>)}</tbody></table></div><p>At a maximum-level facility, an all-Rare-or-better eligible craft has a frozen 3% Peerless chance, or 5% with its matching specialist. The twentieth consecutive eligible craft of the same schematic at that facility is guaranteed; its visible counter resets only when that schematic becomes Peerless.</p></section>
    <section className="article-section"><h2>Choose source detail only when it changes the result</h2><div className="definition-grid">{sourceLotRules.map(([rule, behavior]) => <div key={rule}><h3>{rule}</h3><p>{behavior}</p></div>)}</div></section>
    <section className="article-section"><h2>Processing never applies quality twice</h2><div className="definition-grid">{processingQualityRules.map(([rule, behavior]) => <div key={rule}><h3>{rule}</h3><p>{behavior}</p></div>)}</div><p>An ordinary finished recipe uses no more than one mandatory processing step. A second processing step is reserved for exceptional or capstone work.</p></section>
    <section className="article-section"><h2>Planned processing recipes</h2><p>These first-pass recipes belong to the named specialist and cost no Essence as ordinary processing. They remain planned until each facility’s material-overhaul slice is playable.</p><div className="table-wrap"><table><thead><tr><th>Output</th><th>Input</th><th>Result</th><th>Where it belongs</th></tr></thead><tbody>{processingConversions.map(([output, input, result, owner]) => <tr key={output}><td><strong>{output}</strong></td><td>{input}</td><td>{result}</td><td>{owner}</td></tr>)}</tbody></table></div><p>Named extracts use their own preparation recipes. Rift-glass never becomes ordinary Glass, and no intermediate enters the game until it has at least two real consumers or one broadly reused consumer family.</p></section>
    <section className="article-section"><h2>Preview before making</h2><div className="step-grid"><article><span>1</span><h3>Choose an available station</h3><p>The station and its recipe or schematic must be unlocked before you can prepare that item.</p></article><article><span>2</span><h3>Keep each kind of cost distinct</h3><p>Stored resources, physical materials, Essence Crystals, and Motes are different costs. The game never substitutes one for another.</p></article><article><span>3</span><h3>Confirm what you reviewed</h3><p>The station checks the ingredients, selected materials, recipe, and Storehouse or Waiting destination again. If something changed, review the updated preview before confirming.</p></article></div></section>

    <section className="article-section">
      <h2>Reuse and adjacent services</h2>
      <div className="status-card-grid">
        <article className="status-card"><h3><Link href="/village">Village buildings</Link></h3><p>Check which stations are available, what reveals each foundation, and which services are still planned.</p></article>
        <article className="status-card"><h3><Link href="/recycling">Recycler</Link></h3><p>Dismantle eligible finished gear after reviewing the item, where it is stored, and the materials it will return.</p></article>
        <article className="status-card"><h3><Link href="/research">Research</Link></h3><p>Study capabilities and recipe-related knowledge through its own prerequisites, costs, and permanent progression.</p></article>
        <article className="status-card"><h3><Link href="/trading">Trading Post</Link></h3><p>Buy and sell eligible goods after checking their price, stock, quantity, quality, and destination.</p></article>
      </div>
    </section>
    <RelatedGuides links={[{ label: 'Resources', href: '/resources' }, { label: 'Inventory and storage', href: '/systems/inventory-custody' }, { label: 'Equipment', href: '/equipment' }, { label: 'Current progression', href: '/resources/progression' }, { label: 'Village', href: '/village' }, { label: 'Worlds and harvesting', href: '/world' }]} />
  </SiteFrame>;
}
