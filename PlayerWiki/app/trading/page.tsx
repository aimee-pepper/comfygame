import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import {
  buyableResourceBands,
  itemRoute,
  merchantConsumables,
  ordinaryMerchantGear,
  resourceSalePrices,
  sellableResources,
  tradingStation,
} from '@/lib/trading-reference';

export default function TradingDirectory() {
  const gearBySlot = ordinaryMerchantGear.reduce<Record<string, typeof ordinaryMerchantGear>>(
    (groups, item) => {
      const slot = String(item.gear?.slot ?? 'other');
      (groups[slot] ??= []).push(item);
      return groups;
    },
    {},
  );
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Economy and exchange', href: '/systems/economy-exchange' }, { label: 'Trading Post offers' }]} />
    <div className="entity-heading">
      {tradingStation?.assetURL && <PixelImage src={tradingStation.assetURL} alt="Trading Post building visual" size={96} />}
      <PageIntro eyebrow="Current Village reference" title="Trading Post offers" summary="See the exact current offer pools, purchase terms, and sale rules before comparing them with the stock on Vance’s screen." />
    </div>
    <section className="article-section"><h2>Material offers today and after the approved update</h2><TruthPair current="The Trading Post currently mixes counted resource lines with exact material samples. The shelf and confirmation show the exact stock, quantity, and price that can be committed now." accepted="Physical materials will be bought and sold by domain, family, quality band, and exact quantity. Source history remains inspectable, but does not split the stock. A better grade is never silently sold or purchased in place of the quoted band." /></section>
    <section className="article-section note-card">
      <h2>Check the current shelf before buying</h2>
      <p>The Trading Post is available after its 10-Essence foundation is complete. Its stock refreshes after an expedition resolves, not while you browse. A shelf line has no durable player-facing listing identity, so this directory records the live offer pools and fixed terms instead of claiming that a particular item is always for sale.</p>
      <p><Link href="/buildings/trading-post">Trading Post construction</Link> · <Link href="/services/trading-post">Use the Trading Post</Link></p>
    </section>
    <section className="article-section">
      <h2>Current resource offer pools</h2>
      <div className="table-wrap data-table"><table><thead><tr><th>Pool</th><th>Resources that can appear</th><th>Per displayed resource</th><th>Purchase result</th></tr></thead><tbody>{buyableResourceBands.map((pool) => <tr key={pool.band}><td>{pool.band} resource stock</td><td>{pool.entries.map((resource, index) => <span key={resource.id}>{index ? ', ' : ''}<Link href={`/resources/${resource.slug}`}>{resource.name}</Link></span>)}</td><td>{pool.quantity}<small>{pool.price}</small></td><td>The selected quantity enters the resource reserve after a completed purchase.</td></tr>)}</tbody></table></div>
    </section>
    <section className="article-section">
      <h2>Other current purchase pools</h2>
      <div className="table-wrap data-table"><table><thead><tr><th>Offer</th><th>When it can appear</th><th>Exact current terms</th><th>After a completed purchase</th></tr></thead><tbody>
        <tr><td>Creature material sample</td><td>0–2 physical material samples may be added after a refresh.</td><td>The exact kind, capabilities, quantity, and price are shown on that shelf line.</td><td>The exact selected sample enters the appropriate material reserve.</td></tr>
        <tr><td>Known consumable</td><td>0–2 common or uncommon consumables; recipe-known entries require their current recipe knowledge, while independent entries do not.</td><td>1–2 units of the exact displayed item. The shelf shows its price and remaining stock.</td><td>The selected unit enters Storehouse or Waiting if Storehouse is full.</td></tr>
        <tr><td>Ordinary gear</td><td>One current ordinary-found gear item after a refresh. If no campaign weapon is owned, it is a weapon; otherwise any eligible slot may appear.</td><td>One exact frozen piece at the shelf’s displayed price.</td><td>The exact piece enters Storehouse or Waiting if Storehouse is full.</td></tr>
        <tr><td>Refined Essence</td><td>When the refresh provides 1–3 bundles.</td><td>10 Essence per bundle · 8 Gold per bundle.</td><td>The purchased bundle adds 10 Essence Crystals.</td></tr>
      </tbody></table></div>
    </section>
    <section className="article-section">
      <h2>Known consumables that may enter the pool</h2>
      <p>These are possible offer entries, not a promise that one is on the current shelf.</p>
      <div className="definition-grid">{merchantConsumables.map((item) => <div key={item.id}><Link href={itemRoute(item)}><strong>{item.name}</strong></Link><p>{item.merchantStockAccess === 'independent' ? 'Independent current merchant access.' : 'Can appear once its current recipe is known.'}</p></div>)}</div>
    </section>
    <section className="article-section">
      <h2>Ordinary gear that may enter the pool</h2>
      <p>Only one exact piece is offered at a time. This pool excludes special, singular, and apex-only gear.</p>
      <div className="definition-grid">{Object.entries(gearBySlot).map(([slot, items]) => <div key={slot}><h3>{slot[0].toUpperCase() + slot.slice(1)}</h3><p>{items.map((item, index) => <span key={item.id}>{index ? ', ' : ''}<Link href={itemRoute(item)}>{item.name}</Link></span>)}</p></div>)}</div>
    </section>
    <section className="article-section">
      <h2>Sell from the exact holding shown</h2>
      <div className="table-wrap data-table"><table><thead><tr><th>What you sell</th><th>Current value</th><th>Custody and refusal boundary</th></tr></thead><tbody>
        {sellableResources.map((resource) => <tr key={resource.id}><td><Link href={`/resources/${resource.slug}`}>{resource.name}</Link></td><td>{resourceSalePrices[resource.tradeBand] ?? 'Not a current sale band'}</td><td>Choose a quantity from the resource reserve; it does not use a Storehouse item slot.</td></tr>)}
        <tr><td>Identified transferable item</td><td>Common 2 · Uncommon 5 · Rare 10 · Mythic 20 Gold per unit.</td><td>The exact stored or Waiting stack must still be identified, transferable, and available.</td></tr>
        <tr><td>Eligible physical gear</td><td>At least 4 Gold; the current piece’s effective power sets the shown price.</td><td>Favorites, locked, singular, apex-only, protected-return, and other protected gear remain unsold.</td></tr>
        <tr><td>Material reserve sample</td><td>The selected sample’s displayed value.</td><td>Select an exact material unit; a completed sale makes that unit available as a merchant material line.</td></tr>
        <tr><td>Refined Essence</td><td>10 Essence Crystals for 1 Gold.</td><td>Only whole 10-Crystal bundles can be selected.</td></tr>
      </tbody></table></div>
    </section>
    <section className="article-section note-card"><h2>Cancel, refusal, and stock changes</h2><p>Opening a listing, changing quantity, Cancel, or Back does not move currency, resources, items, or material samples. If funds, stock, identity, capacity, or the current revision changes before confirmation, review the refreshed line: the previous offer stays uncommitted.</p></section>
    <RelatedGuides links={[{ label: 'Economy and exchange', href: '/systems/economy-exchange' }, { label: 'Trading Post service', href: '/services/trading-post' }, { label: 'Trading Post building', href: '/buildings/trading-post' }, { label: 'Resources', href: '/resources' }, { label: 'Equipment', href: '/equipment' }, { label: 'Consumables', href: '/consumables' }, { label: 'Storehouse and inventory', href: '/systems/inventory-custody' }]} />
  </SiteFrame>;
}
