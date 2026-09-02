import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { craftingSystems } from '@/lib/crafting';
import { content } from '@/lib/content';
import { craftingFamilyStatus } from '@/lib/player-guide-status';

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
    <PageIntro
      eyebrow="Production directory"
      title="Crafting systems"
      summary="Choose one station or production family. Every system now has its own page for access, current recipes, intended ingredient rules, outputs, refusals, and related resources."
    />

    <section className="article-section note-card">
      <h2>Use this page as a directory</h2>
      <p>This page no longer repeats every recipe from every station. Open the system you are using for its complete <strong>Implemented now</strong> and <strong>Intended implementation</strong> details.</p>
      <TruthPair current="Each system page lists the recipes, inputs, outputs, access, and limitations available in the current game." accepted="Each same system page separately explains its accepted physical-material categories, quality behavior, result statistics, and changes that are not implemented yet." acceptedLabel="Intended organization" />
      <nav aria-label="Shared crafting rules">
        <Link href="/systems/crafting">Recipe and ingredient rules</Link>
        <Link href="/resources">Materials and acquisition</Link>
        <Link href="/systems/inventory-custody">Quality, stacks, and custody</Link>
        <Link href="/systems/equipment-materials">Equipment results and material effects</Link>
        <Link href="/resources/progression">Resource and facility progression</Link>
        <Link href="/world">World generation and harvesting</Link>
      </nav>
    </section>

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
            <p><Link href={`/crafting/${slug}`}>Open the complete {system.name} guide</Link></p>
          </article>;
        })}
      </div>
    </section>)}

    <section className="article-section">
      <h2>Reuse and adjacent services</h2>
      <div className="status-card-grid">
        <article className="status-card"><h3><Link href="/village">Village buildings</Link></h3><p>Check which station is currently available, what opens its foundation, and which services are scheduled rather than live.</p></article>
        <article className="status-card"><h3><Link href="/recycling">Recycler</Link></h3><p>Dismantle an eligible finished item through its own preview, custody, yield, and intended material-return rules.</p></article>
        <article className="status-card"><h3><Link href="/research">Research</Link></h3><p>Study capabilities and recipe-related knowledge through its own prerequisites, costs, and permanent progression.</p></article>
        <article className="status-card"><h3><Link href="/trading">Trading Post</Link></h3><p>Buy and sell exact eligible holdings through its own price, stock, quantity, quality, and custody rules.</p></article>
      </div>
    </section>
  </SiteFrame>;
}
