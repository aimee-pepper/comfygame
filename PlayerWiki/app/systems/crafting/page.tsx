import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { content } from '@/lib/content';
import { craftingSystems } from '@/lib/crafting';

export default function Crafting() {
  const stationNames = ['Storehouse', 'The Apothecary', 'Essence Spring'];
  const stationReferences = stationNames
    .map((name) => content.stations.find((station) => station.name === name))
    .filter((station) => station?.assetURL);

  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Crafting and materials' }]} />
      <PageIntro
        eyebrow="System guide"
        title="Crafting and materials"
        summary="Returned resources support construction, processing, supplies, equipment, research, and station work. This guide separates today's exact-sample system from the intended physical-material recipe system."
      />
      <section className="article-section crafting-route-guide">
        <h2>Follow the material through the Village</h2>
        <p>These retained place visuals point to the three screens most useful when deciding what to make: check what you carry, choose a preparation, then refine the currency a result requires.</p>
        <div className="crafting-route-strip">
          {stationReferences.map((station) => station && <Link key={station.id} href={`/places/${station.slug}`}><PixelImage src={station.assetURL} alt={`${station.name} building visual`} size={64} /><span><strong>{station.name}</strong><small>{station.blurb}</small></span></Link>)}
        </div>
      </section>
      <section className="article-section">
        <h2>Current game and intended replacement</h2>
        <TruthPair current="Current makers combine counted resources, exact source-bearing samples, fixed costs, and hidden hardness, density, insulation, flexibility, lustre, or reactivity thresholds. Each station's current page lists the exact live rule." accepted="Recipes use static ingredients plus visible broad, specific, or precise physical categories. The player selects a physical type or subtype and Poor, Common, Rare, or Exceptional quality; the preview shows direct contributions to real item statistics." acceptedLabel="Intended design" />
        <p><Link href="/crafting">Open the complete system-by-system and recipe-by-recipe comparison</Link></p>
      </section>
      <section className="article-section">
        <h2>Read the current preview before making</h2>
        <div className="step-grid">
          <article>
            <span>1</span>
            <h3>Choose a revealed station</h3>
            <p>
              A station, known recipe or schematic, and its access rule must all
              be available before its current preview can be used.
            </p>
          </article>
          <article>
            <span>2</span>
            <h3>Keep cost forms distinct</h3>
            <p>
              Stored resources, exact materials, Essence Crystals, and Motes are
              different kinds of cost. A counted resource cannot replace an exact
              selected material.
            </p>
          </article>
          <article>
            <span>3</span>
            <h3>Commit the quoted result</h3>
            <p>
              The station rechecks ingredients, the selected material, recipe,
              and legal Storehouse or Waiting destination. A changed quote needs
              a fresh preview.
            </p>
          </article>
        </div>
      </section>
      <section className="article-section two-column">
        <div>
        <h2>Material effects</h2>
          <p>
            The intended recipe fixes the item's function, while the selected
            physical material and resource quality contribute directly to its
            visible statistics. There is no equipment durability system.
          </p>
          <p>
            <Link href="/resources">Browse resources</Link>
          </p>
        </div>
        <div>
          <h2>Construction</h2>
          <p>
            Village buildings unlock services and new preparation options.
            Construction costs are listed on each Place page so you can plan a
            return haul around the next useful build.
          </p>
          <p>
            <Link href="/places">Browse places and stations</Link>
          </p>
        </div>
      </section>
      <section className="article-section">
        <h2>Instruments and prepared ink</h2>
        <p>Current instruments and prepared ink are documented as station processes rather than standalone catalogue item records. Their exact inputs, outputs, and material rules stay with the station that prepares or improves them.</p>
        <div className="definition-grid">{craftingSystems.filter((system) => ['instruments', 'writing-ink'].includes(system.slug)).map((system) => <div key={system.slug}><h3><Link href={`/crafting/${system.slug}`}>{system.name}</Link></h3><p>{system.summary}</p></div>)}</div>
      </section>
      <section className="article-section">
        <h2>Other useful stations</h2>
        <ul>
          <li>
            <strong><Link href="/recycling">Recycler:</Link></strong> dismantles eligible gear into a previewed
            yield.
          </li>
          <li>
            <strong><Link href="/systems/research">Research</Link>:</strong> spends the shown cost to unlock a
            selected node.
          </li>
          <li>
            <strong><Link href="/trading">Trading Post:</Link></strong> buys and sells eligible stock using
            the current listing and quantity.
          </li>
          <li>
            <strong>Firepit:</strong> manages who is travelling with the party
            and who remains at home.
          </li>
        </ul>
      </section>
      <RelatedGuides links={[{ label: 'Crafting systems', href: '/crafting' }, { label: 'Trading offer reference', href: '/trading' }, { label: 'Recycler return reference', href: '/recycling' }, { label: 'Village services', href: '/services' }, { label: 'Resource table', href: '/resources' }, { label: 'Equipment table', href: '/equipment' }]} />
    </SiteFrame>
  );
}
