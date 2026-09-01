import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
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
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Economy and exchange', href: '/systems/economy-exchange' }, { label: 'Recycler returns' }]} />
    <div className="entity-heading">
      {recyclerStation?.assetURL && <PixelImage src={recyclerStation.assetURL} alt="Recycler building visual" size={96} />}
      <PageIntro eyebrow="Current Village reference" title="Recycler returns" summary="Compare the standard salvage profiles and the exact preview rules before choosing one eligible piece to dismantle." />
    </div>
    <section className="article-section note-card">
      <h2>Noll’s first Recycler</h2>
      <p>Recruit <Link href="/people/noll">Noll</Link> to reveal the Recycler foundation in Home → Make. Its complete build cost is <strong>{recyclerFirstUse.buildCost}</strong>. Building it creates the bench, not a dismantling result.</p>
      <ol className="numbered-guide">{recyclerFirstUse.journey.map((step) => <li key={step}>{step}</li>)}</ol>
      <p>{recyclerFirstUse.emptyState}</p>
      <p>A recovery preview belongs to one current Stored or Waiting physical piece and its current state, so it has no durable player-facing transaction ID. This directory records authored standard profiles; use Noll’s current preview for the exact selected holding.</p>
      <p><Link href="/buildings/recycler">Recycler construction</Link> · <Link href="/services/recycler">Use the Recycler</Link></p>
    </section>
    <section className="article-section">
      <h2>Standard salvage profiles</h2>
      <p>For an authored standard profile, lower construction tiers return the first one or two entries; tier 4 and above returns all three. An exact physical construction receipt follows its own recorded samples instead.</p>
      <div className="table-wrap data-table"><table><thead><tr><th>Profile</th><th>Tier 1–2 return</th><th>Tier 3 return</th><th>Tier 4+ return</th></tr></thead><tbody>{Object.keys(authoredSalvageProfiles).map((profileID) => <tr key={profileID}><td>{gearByProfile[profileID]?.map((item, index) => <span key={item.id}>{index ? ', ' : ''}<Link href={`/equipment/${item.slug}`}>{item.name}</Link></span>) ?? 'No current gear entry'}</td><td>{recyclerOutputForTier(profileID, 1).map(resourceName).join(' · ')}</td><td>{recyclerOutputForTier(profileID, 2).map(resourceName).join(' · ')}</td><td>{recyclerOutputForTier(profileID, 3).map(resourceName).join(' · ')}</td></tr>)}</tbody></table></div>
    </section>
    <section className="article-section">
      <h2>Construction-receipt recovery</h2>
      <div className="definition-grid"><div><h3>Read the recorded samples</h3><p>A piece that records its construction samples returns only selected samples from that exact receipt, not a guessed standard profile.</p></div><div><h3>Current service tier</h3><p>Tier 1 can recover 40%, tier 2 55%, and tier 3 70% of a receipt. A receipt must contain at least two samples; the current preview names the selected units.</p></div><div><h3>Keep the preview current</h3><p>Changing the selected piece, its ownership, or the Recycler’s current state means reopening the exact preview before recovery.</p></div></div>
    </section>
    <section className="article-section two-column"><div><h2>Choose one exact piece</h2><ul className="compact-list">{recyclerFirstUse.selection.map((line) => <li key={line}>{line}</li>)}</ul></div><div><h2>Keep protected gear intact</h2><p>{recyclerFirstUse.protected}</p></div></section>
    <section className="article-section">
      <h2>When a piece stays protected</h2>
      <div className="definition-grid"><div><h3>Prepare the piece</h3><p>Separate a stack, identify the piece, remove Favorite and Lock, and take worn gear off before opening the Recycler preview.</p></div><div><h3>Keep protected gear intact</h3><p>Protected returns, one-of-a-kind and apex gear, story items, Channelworks property, and legacy-powered gear are not dismantled here.</p></div><div><h3>Use a defined return</h3><p>Non-gear belongings, pieces without recorded construction stock or standard salvage, and found receipts with no recoverable units remain unavailable.</p></div></div>
    </section>
    <section className="article-section note-card"><h2>Confirm only the displayed preview</h2><p>{recyclerFirstUse.zeroOutput}</p><ul className="compact-list">{recyclerFirstUse.boundaries.map((line) => <li key={line}>{line}</li>)}</ul><p>{recyclerFirstUse.exclusion}</p></section>
    <RelatedGuides links={[{ label: 'Economy and exchange', href: '/systems/economy-exchange' }, { label: 'Recycler service', href: '/services/recycler' }, { label: 'Recycler building', href: '/buildings/recycler' }, { label: 'Equipment', href: '/equipment' }, { label: 'Resources', href: '/resources' }, { label: 'Storehouse and inventory', href: '/systems/inventory-custody' }]} />
  </SiteFrame>;
}
