"use client";

import { useSyncExternalStore } from 'react';
import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { serviceGuides } from '@/lib/services';
import { playerStartGuides, systemGuides } from '@/lib/system-guides';
import { villageBuildings } from '@/lib/village';
import { floraHarvestProfiles, terrainProfiles, worldConditions } from '@/lib/world-reference';
import { craftingSystems, recipeReadiness, recipesFor } from '@/lib/crafting';
import { statusReferences } from '@/lib/status-reference';
import { techniqueReferences } from '@/lib/technique-reference';
import { actionReferences } from '@/lib/action-reference';

export default function SearchPage() {
  const q = useSyncExternalStore(
    () => () => {},
    () => (new URLSearchParams(window.location.search).get('q') ?? '').trim().toLowerCase(),
    () => '',
  );
  const categories = [
    { label: 'Player guides', entries: [...playerStartGuides, ...systemGuides].map((entry) => ({ name: entry.label, summary: entry.summary, href: entry.href, type: 'Player guide', assetURL: null, alt: '' })) },
    { label: 'Resources', entries: content.resources.map(entry => ({ name: entry.name, summary: entry.summary, href: `/resources/${entry.slug}`, type: 'Resource', assetURL: entry.assetURL, alt: `${entry.name} inventory icon` })) },
    { label: 'Equipment', entries: content.items.filter(entry => entry.gear).map(entry => ({ name: entry.name, summary: entry.summary, href: `/equipment/${entry.slug}`, type: 'Equipment', assetURL: entry.assetURL, alt: `${entry.name} icon` })) },
    { label: 'Supplies', entries: content.items.filter(entry => !entry.gear && entry.consumable).map(entry => ({ name: entry.name, summary: entry.summary, href: `/items/${entry.slug}`, type: 'Supply', assetURL: entry.assetURL, alt: `${entry.name} icon` })) },
    { label: 'Curios and key items', entries: content.items.filter(entry => !entry.gear && !entry.consumable).map(entry => ({ name: entry.name, summary: entry.summary, href: `/items/${entry.slug}`, type: 'Curio or key item', assetURL: entry.assetURL, alt: `${entry.name} icon` })) },
    { label: 'People and records', entries: content.cast.flatMap((entry) => [
      { name: entry.name, summary: `${entry.meetingContext} ${entry.contribution}`, href: `/people/${entry.slug}`, type: 'Person', assetURL: entry.assetURL, alt: `${entry.name} character visual` },
      ...entry.diaryPages.map((page) => ({
        name: `${entry.name}: ${page.title} — page ${page.sequence}`,
        summary: page.prose,
        href: `/people/${entry.slug}#${page.worldHint ? 'location-hints' : 'diary-pages'}`,
        type: page.worldHint ? 'Spoiler-marked location hint' : 'Authored book page',
        assetURL: null,
        alt: '',
      })),
    ]) },
    { label: 'Village buildings', entries: villageBuildings.map(entry => ({ name: entry.name, summary: entry.status === 'scheduled' ? `${entry.blurb} Scheduled; not yet a live player route.` : entry.blurb, href: `/buildings/${entry.slug}`, type: entry.status === 'scheduled' ? 'Scheduled building' : 'Current Village building', assetURL: entry.assetURL ?? entry.contextAssetURL, alt: entry.assetURL ? `${entry.name} building visual` : `${entry.zone} town setting` })) },
    { label: 'Village services', entries: serviceGuides.map(entry => { const station = content.stations.find((candidate) => candidate.id === entry.stationID); return { name: entry.name, summary: entry.summary, href: `/services/${entry.slug}`, type: 'Service guide', assetURL: station?.assetURL ?? station?.contextAssetURL ?? null, alt: station?.assetURL ? `${station.name} building visual` : `${station?.zone ?? 'Village'} town setting` }; }) },
    { label: 'Economy references', entries: [
      { name: 'Trading Post offers', summary: 'Current rotating offer pools, purchase terms, sale prices, custody outcomes, and refusal boundaries.', href: '/trading', type: 'Current economy reference', assetURL: content.stations.find((station) => station.id === 'trading_post')?.assetURL ?? null, alt: 'Trading Post building visual' },
      { name: 'Recycler returns', summary: 'Standard salvage profiles, construction-receipt recovery, protected pieces, and committed-only dismantling.', href: '/recycling', type: 'Current economy reference', assetURL: content.stations.find((station) => station.id === 'recycler')?.assetURL ?? null, alt: 'Recycler building visual' },
    ] },
    { label: 'Current crafting', entries: craftingSystems.flatMap(system => [{ name: system.name, summary: `${system.station}. ${system.access[0]}`, href: `/crafting/${system.slug}`, type: 'Current station process', assetURL: content.stations.find(station => station.id === system.stationID)?.assetURL ?? null, alt: `${system.station} building visual` }, ...recipesFor(system.slug).map(recipe => ({ name: recipe.name, summary: `${recipe.result}. ${recipeReadiness(recipe)}`, href: `/crafting/${system.slug}`, type: 'Current recipe', assetURL: content.items.find(item => item.name === recipe.result)?.assetURL ?? null, alt: `${recipe.result} icon` }))]) },
    { label: 'World conditions', entries: worldConditions.map(entry => ({ name: entry.name, summary: entry.blurb, href: `/world/conditions/${entry.slug}`, type: 'World condition', assetURL: null, alt: '' })) },
    { label: 'Terrain', entries: terrainProfiles.map(entry => ({ name: entry.name, summary: `${entry.movement} ${entry.sight}`, href: `/terrain/${entry.slug}`, type: 'Terrain profile', assetURL: entry.assetURL, alt: entry.assetURL ? `${entry.name} terrain visual` : '' })) },
    { label: 'Flora harvest relationships', entries: floraHarvestProfiles.map(entry => ({ name: entry.name, summary: entry.summary, href: `/flora/${entry.slug}`, type: 'Flora harvest relationship', assetURL: content.resources.find((resource) => resource.id === entry.resultID)?.assetURL ?? null, alt: '' })) },
    { label: 'World records', entries: (() => { const guide = serviceGuides.find((entry) => entry.slug === 'bestiary'); const station = content.stations.find((entry) => entry.id === 'bestiary'); return guide ? [{ name: 'Bestiary', summary: guide.summary, href: '/bestiary', type: 'World record guide', assetURL: station?.assetURL ?? station?.contextAssetURL ?? null, alt: station?.assetURL ? `${station.name} building visual` : 'Village setting' }] : []; })() },
    { label: 'Creatures and threats', entries: content.creatures.map(entry => ({ name: entry.name, summary: `Tier ${entry.tier} · ${entry.isNocturnal ? 'night' : 'day'} profile · ${entry.maxHP} health`, href: `/bestiary/${entry.slug}`, type: 'Current encounter profile', assetURL: null, alt: '' })) },
    { label: 'Sites', entries: content.sites.map(entry => ({ name: entry.name, summary: entry.blurb, href: `/sites/${entry.slug}`, type: 'Current site profile', assetURL: null, alt: '' })) },
    { label: 'Conditions and effects', entries: statusReferences.map(entry => ({ name: entry.name, summary: `${entry.category}. ${entry.summary}`, href: `/statuses/${entry.slug}`, type: 'Current condition or effect', assetURL: null, alt: '' })) },
    { label: 'Techniques and Gambits', entries: techniqueReferences.map(entry => ({ name: entry.name, summary: `${entry.group}. ${entry.result}`, href: `/techniques/${entry.slug}`, type: entry.group, assetURL: null, alt: '' })) },
    { label: 'Actions', entries: actionReferences.map(entry => ({ name: entry.name, summary: `${entry.group}. ${entry.change}`, href: `/actions/${entry.slug}`, type: 'Current player action', assetURL: null, alt: '' })) },
    { label: 'Glossary', entries: content.terminology.map(entry => ({ name: entry.name, summary: entry.summary, href: `/glossary#${entry.slug}`, type: 'Term', assetURL: null, alt: '' })) },
  ];
  const groups = q ? categories.map((category) => ({ ...category, entries: category.entries.filter(entry => `${entry.name} ${entry.summary} ${entry.type} ${category.label}`.toLowerCase().includes(q)) })).filter((category) => category.entries.length) : [];
  const resultCount = groups.reduce((total, group) => total + group.entries.length, 0);
  return <SiteFrame sidebar><PageIntro eyebrow="Player Wiki" title={q ? `Search results for “${q}”` : 'Search'} summary={q ? `${resultCount} matching player-facing entries.` : 'Enter a name, item, resource, place, or game term in the search field.'} />
    {q && !groups.length && <section className="article-section note-card"><h2>No matching player entries</h2><p>Try a shorter name, an item type, a resource, or a Village service.</p></section>}
    {groups.map(group => <section className="article-section search-group" key={group.label}><h2>{group.label} <span>{group.entries.length}</span></h2><div className="table-wrap data-table catalogue-summary"><table><thead><tr><th aria-label="Image" /><th>Result</th><th>Type</th><th>Summary</th></tr></thead><tbody>{group.entries.map(result => <tr key={`${result.href}-${result.type}-${result.name}`}><td>{result.assetURL ? <Link href={result.href} aria-label={`Open ${result.name}`}><PixelImage src={result.assetURL} alt={result.alt} /></Link> : '—'}</td><td><Link href={result.href}>{result.name}</Link></td><td>{result.type}</td><td>{result.summary}</td></tr>)}</tbody></table></div></section>)}
  </SiteFrame>;
}
