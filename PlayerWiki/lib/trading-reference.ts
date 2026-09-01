import { content } from '@/lib/content';

export const tradingStation = content.stations.find(
  (station) => station.id === 'trading_post',
);

export const buyableResourceBands = [
  {
    band: 'Staple',
    quantity: '3–8 units per displayed resource',
    price: '3 Gold per unit',
    entries: content.resources.filter((resource) => resource.tradeBand === 'Staple'),
  },
  {
    band: 'Uncommon',
    quantity: '1–3 units per displayed resource',
    price: '6 Gold per unit',
    entries: content.resources.filter((resource) => resource.tradeBand === 'Uncommon'),
  },
];

export const merchantConsumables = content.items.filter(
  (item) =>
    Boolean(item.consumable) &&
    ['common', 'uncommon'].includes(item.rarity) &&
    item.merchantStockAccess !== null,
);

export const ordinaryMerchantGear = content.items.filter(
  (item) => Boolean(item.gear) && item.ordinaryMerchantGear,
);

export const sellableResources = content.resources.filter(
  (resource) => resource.tradeBand !== 'Nontradeable',
);

export const resourceSalePrices: Record<string, string> = {
  Staple: '1 Gold per unit',
  Uncommon: '2 Gold per unit',
  Rare: '5 Gold per unit',
  Precious: '12 Gold per unit',
};

export function itemRoute(item: (typeof content.items)[number]) {
  return item.gear ? `/equipment/${item.slug}` : `/items/${item.slug}`;
}
