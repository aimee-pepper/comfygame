import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import {
  authoredSalvageProfiles,
  recyclerOutputForTier,
  recyclerStation,
  resourceName,
  standardRecyclerGear,
} from '@/lib/recycling-reference';
import { recyclerFirstUse } from '@/lib/recycler-first-use';

export default function RecyclingDirectory() {
  const gearByProfile = standardRecyclerGear.reduce<Record<string, typeof standardRecyclerGear>>(
    (groups, item) => {
      const profile = item.salvageProfileID;
      if (profile) (groups[profile] ??= []).push(item);
      return groups;
    },
    {},
  );
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Economy and exchange', href: '/trading' }, { label: 'Recycler returns' }]} />
    <div className="entity-heading">
      {recyclerStation?.assetURL && <PixelImage src={recyclerStation.assetURL} alt="Recycler building visual" size={96} />}
      <PageIntro eyebrow="Current Village reference" title="Recycler returns" summary="Compare what different kinds of gear can return, then review the exact materials before choosing one piece to dismantle." />
    </div>
    <section className="article-section"><h2>Materials returned now and in the intended design</h2><TruthPair current="The Recycler dismantles one eligible piece at a time. Gear with recorded construction materials returns selected parts of those materials; older standard gear follows its listed salvage pattern." accepted="The same one-piece rule remains. Mined materials and ordinary flora return to their exact-name or subtype quantity stacks with no quality. Creature materials return to their recorded subtype, quality, and quantity stacks with species details still available. The Recycler never invents or substitutes a quality." /></section>
    <section className="article-section">
      <h2>Planned Rubble sorting</h2>
      <TruthPair
        current="Rubble is currently a counted resource, and the Recycler currently accepts eligible gear rather than raw Rubble."
        accepted="Rubble remains one simple, ungraded mixed resource. A separate Recycler action will let you choose an amount and preview the materials hidden in those exact units. The source region controls what can appear: common local materials appear most often, uncommon finds appear less often, and a genuinely rare local material is only a small bonus chance."
        acceptedLabel="Intended design"
      />
      <p>The Recycler will never produce a material that was absent from the Rubble’s source region. Once shown, a preview cannot be changed by cancelling, reopening, or relaunching. This action is still planned rather than playable.</p>
      <div className="table-wrap"><table><tbody><tr><th>Amount</th><td>Choose 2, 4, or 6 Rubble from one source-region batch.</td></tr><tr><th>Cost</th><td>Recycler level 1 · 0 Essence · 0 world turns.</td></tr><tr><th>Base result</th><td>One local material for every 2 Rubble. The first is always common; each later result is 75% common and 25% uncommon.</td></tr><tr><th>Rare local bonus</th><td>Sorting 4 or 6 Rubble has one 5% chance for one extra rare material that existed in that region.</td></tr><tr><th>Unavailable pool</th><td>If the region has no uncommon or rare material, that outcome cannot appear.</td></tr></tbody></table></div>
      <p><Link href="/references/resource-world-numbers-decided-so-far">Read the complete first-pass resource and world rules</Link>.</p>
    </section>
    <section className="article-section note-card">
      <h2>Noll’s first Recycler</h2>
      <p>Recruit <Link href="/people/noll">Noll</Link> to reveal the Recycler foundation in Home → Make. Its complete build cost is <strong>{recyclerFirstUse.buildCost}</strong>. Building it creates the bench, not a dismantling result.</p>
      <ol className="numbered-guide">{recyclerFirstUse.journey.map((step) => <li key={step}>{step}</li>)}</ol>
      <p>{recyclerFirstUse.emptyState}</p>
      <p>Every recovery preview belongs to the Stored or Waiting piece you selected. Use Noll’s preview to see what that particular item will return before you dismantle it.</p>
      <p><Link href="/buildings/recycler">Open the complete Recycler entry</Link></p>
    </section>
    <section className="article-section">
      <h2>Standard salvage patterns</h2>
      <p>For standard gear, lower construction tiers return the first one or two listed materials; tier 4 and above returns all three. Gear that remembers its construction materials returns from that recorded list instead.</p>
      <div className="table-wrap data-table"><table><thead><tr><th>Gear family</th><th>Tier 1–2 return</th><th>Tier 3 return</th><th>Tier 4+ return</th></tr></thead><tbody>{Object.keys(authoredSalvageProfiles).map((profileID) => <tr key={profileID}><td>{gearByProfile[profileID]?.map((item, index) => <span key={item.id}>{index ? ', ' : ''}<Link href={`/equipment/${item.slug}`}>{item.name}</Link></span>) ?? 'No current gear entry'}</td><td>{recyclerOutputForTier(profileID, 1).map(resourceName).join(' · ')}</td><td>{recyclerOutputForTier(profileID, 2).map(resourceName).join(' · ')}</td><td>{recyclerOutputForTier(profileID, 3).map(resourceName).join(' · ')}</td></tr>)}</tbody></table></div>
    </section>
    <section className="article-section">
      <h2>Recovering recorded construction materials</h2>
      <div className="definition-grid"><div><h3>Read the material history</h3><p>If a piece remembers which materials made it, the Recycler returns only from that list rather than guessing from a standard pattern.</p></div><div><h3>Recycler tier</h3><p>Tier 1 can recover 40%, tier 2 55%, and tier 3 70% of the recorded materials. The item must record at least two samples, and the preview names the units selected for recovery.</p></div><div><h3>Review changes</h3><p>If you choose another piece, move it, or change the Recycler, reopen the preview before dismantling.</p></div></div>
    </section>
    <section className="article-section two-column"><div><h2>Choose one exact piece</h2><ul className="compact-list">{recyclerFirstUse.selection.map((line) => <li key={line}>{line}</li>)}</ul></div><div><h2>Keep protected gear intact</h2><p>{recyclerFirstUse.protected}</p></div></section>
    <section className="article-section">
      <h2>When a piece stays protected</h2>
      <div className="definition-grid"><div><h3>Prepare the piece</h3><p>Separate a stack, identify the piece, remove Favorite and Lock, and take worn gear off before opening the Recycler preview.</p></div><div><h3>Keep protected gear intact</h3><p>Protected returns, one-of-a-kind and apex gear, story items, Channelworks equipment, and legacy-powered gear cannot be dismantled here.</p></div><div><h3>Use a known material return</h3><p>Non-gear belongings and pieces with no recorded construction materials or standard salvage pattern remain unavailable.</p></div></div>
    </section>
    <section className="article-section note-card"><h2>Confirm only the displayed preview</h2><p>{recyclerFirstUse.zeroOutput}</p><ul className="compact-list">{recyclerFirstUse.boundaries.map((line) => <li key={line}>{line}</li>)}</ul><p>{recyclerFirstUse.exclusion}</p></section>
    <RelatedGuides links={[{ label: 'Economy and exchange', href: '/trading' }, { label: 'Recycler facility', href: '/buildings/recycler' }, { label: 'Equipment', href: '/equipment' }, { label: 'Resources', href: '/resources' }, { label: 'Inventory and storage', href: '/systems/inventory-custody' }]} />
  </SiteFrame>;
}
