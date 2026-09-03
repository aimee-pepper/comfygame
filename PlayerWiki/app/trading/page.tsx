import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { content } from '@/lib/content';
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
  const recycler = content.stations.find((station) => station.id === 'recycler');
  const spring = content.stations.find((station) => station.id === 'essence_spring');
  const rawEssence = content.resources.find((resource) => resource.id === 'raw_essence');
  const mote = content.resources.find((resource) => resource.id === 'mote');
  const gearBySlot = ordinaryMerchantGear.reduce<Record<string, typeof ordinaryMerchantGear>>(
    (groups, item) => {
      const slot = String(item.gear?.slot ?? 'other');
      (groups[slot] ??= []).push(item);
      return groups;
    },
    {},
  );
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Economy and exchange' }]} />
    <div className="entity-heading">
      {tradingStation?.assetURL && <PixelImage src={tradingStation.assetURL} alt="Trading Post building visual" size={96} />}
      <PageIntro eyebrow="Current Village reference" title="Economy and exchange" summary="Use one economy guide for Trading Post offers, Essence refinement, and Recycler returns. Each linked facility or item page holds its complete individual details." />
    </div>
    <section className="article-section journey-strip">{tradingStation?.assetURL && <Link href="/buildings/trading-post"><PixelImage src={tradingStation.assetURL} alt="Trading Post building visual" size={64} /><span><strong>Trading Post</strong><small>Buy what is in stock or sell an eligible item or material.</small></span></Link>}{spring?.assetURL && <Link href="/buildings/essence-spring"><PixelImage src={spring.assetURL} alt="Essence Spring building visual" size={64} /><span><strong>Essence Spring</strong><small>Refine Raw Essence into spendable Essence Crystals.</small></span></Link>}{recycler?.assetURL && <Link href="/recycling"><PixelImage src={recycler.assetURL} alt="Recycler building visual" size={64} /><span><strong>Recycler</strong><small>See what one eligible piece of gear will return before dismantling it.</small></span></Link>}</section>
    <section className="article-section"><h2>Material offers now and in the intended system</h2><TruthPair current="The Trading Post currently mixes counted resources with individual material samples. The shelf and confirmation show the exact stock, quantity, and price available now." accepted="Mined resources will be bought and sold by exact material and quantity, with no quality variants. Approved biological materials will be bought and sold by subtype, quality, and quantity, with species and source history available inside the stack. The Trading Post will never substitute a different material or quality for the one you chose." /></section>
    <section className="article-section note-card">
      <h2>Check the current shelf before buying</h2>
      <p>The Trading Post is available after its 10-Essence foundation is complete. Its stock changes after an expedition ends, not while you browse. The individual items on its shelves can change, so this page lists what may appear instead of promising that a particular item will always be for sale.</p>
      <p><Link href="/buildings/trading-post">Open the complete Trading Post entry</Link></p>
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
        <tr><td>Ordinary gear</td><td>One ordinary piece of found gear after a refresh. If you do not own a weapon yet, it will be a weapon; otherwise any eligible slot may appear.</td><td>The exact piece shown, at the displayed price.</td><td>The purchased piece enters the Storehouse, or Waiting if the Storehouse is full.</td></tr>
        <tr><td>Refined Essence</td><td>When the refresh provides 1–3 bundles.</td><td>10 Essence per bundle · 8 Gold per bundle.</td><td>The purchased bundle adds 10 Essence Crystals.</td></tr>
      </tbody></table></div>
    </section>
    <section className="article-section">
      <h2>Known consumables that may enter the pool</h2>
      <p>These are possible offer entries, not a promise that one is on the current shelf.</p>
      <div className="definition-grid">{merchantConsumables.map((item) => <div key={item.id}><Link href={itemRoute(item)}><strong>{item.name}</strong></Link><p>{item.merchantStockAccess === 'independent' ? 'Can appear in merchant stock on its own.' : 'Can appear after you learn its recipe.'}</p></div>)}</div>
    </section>
    <section className="article-section">
      <h2>Ordinary gear that may enter the pool</h2>
      <p>Only one exact piece is offered at a time. This pool excludes special, singular, and apex-only gear.</p>
      <div className="definition-grid">{Object.entries(gearBySlot).map(([slot, items]) => <div key={slot}><h3>{slot[0].toUpperCase() + slot.slice(1)}</h3><p>{items.map((item, index) => <span key={item.id}>{index ? ', ' : ''}<Link href={itemRoute(item)}>{item.name}</Link></span>)}</p></div>)}</div>
    </section>
    <section className="article-section">
      <h2>Sell only what you selected</h2>
      <div className="table-wrap data-table"><table><thead><tr><th>What you sell</th><th>Current value</th><th>Where it comes from and when it stays put</th></tr></thead><tbody>
        {sellableResources.map((resource) => <tr key={resource.id}><td><Link href={`/resources/${resource.slug}`}>{resource.name}</Link></td><td>{resourceSalePrices[resource.tradeBand] ?? 'Not a current sale band'}</td><td>Choose a quantity from the resource reserve; it does not use a Storehouse item slot.</td></tr>)}
        <tr><td>Identified transferable item</td><td>Common 2 · Uncommon 5 · Rare 10 · Mythic 20 Gold per unit.</td><td>The exact stored or Waiting stack must still be identified, transferable, and available.</td></tr>
        <tr><td>Eligible physical gear</td><td>At least 4 Gold; the current piece’s effective power sets the shown price.</td><td>Favorites, locked, singular, apex-only, protected-return, and other protected gear remain unsold.</td></tr>
        <tr><td>Material reserve sample</td><td>The selected sample’s displayed value.</td><td>Select an exact material unit; a completed sale makes that unit available as a merchant material line.</td></tr>
        <tr><td>Refined Essence</td><td>10 Essence Crystals for 1 Gold.</td><td>Only whole 10-Crystal bundles can be selected.</td></tr>
      </tbody></table></div>
    </section>
    <section className="article-section note-card"><h2>If you cancel or the stock changes</h2><p>Opening a listing, changing quantity, choosing Cancel, or going Back does not move money or goods. If your funds, the stock, the selected item, or your available space changes before confirmation, review the refreshed offer before trading.</p></section>
    <section className="article-section two-column"><div><h2>Refine Raw Essence</h2><p>At the Essence Spring, choose an amount of {rawEssence ? <Link href={`/resources/${rawEssence.slug}`}>Raw Essence</Link> : 'Raw Essence'}, review how many Essence Crystals you will receive, then confirm. Raw Essence and spendable Essence remain distinct.</p><p>If the amount or rate changes before confirmation, your Raw Essence remains unchanged.</p></div><div><h2>Recycle one piece of gear</h2><p>Select eligible Stored gear and read its dismantling preview. Previewing changes nothing; only a successful dismantle removes the selected piece and adds the materials shown.</p><p><Link href="/recycling">Open the complete Recycler entry</Link></p></div></section>
    <section className="article-section note-card"><h2>Keep currencies and belongings distinct</h2><p>Gold, spendable Essence, Raw Essence, resources, physical materials, and items are separate. {mote ? <><Link href={`/resources/${mote.slug}`}>{mote.name}</Link> is a special currency and is not ordinarily traded. </> : null}The confirmation names what will move, and the game never substitutes something else.</p></section>
    <RelatedGuides links={[{ label: 'Trading Post', href: '/buildings/trading-post' }, { label: 'Recycler', href: '/recycling' }, { label: 'Essence Spring', href: '/buildings/essence-spring' }, { label: 'Resources', href: '/resources' }, { label: 'Equipment', href: '/equipment' }, { label: 'Consumables', href: '/consumables' }, { label: 'Inventory and storage', href: '/systems/inventory-custody' }]} />
  </SiteFrame>;
}
