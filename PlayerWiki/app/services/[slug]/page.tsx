import type { Metadata } from 'next';
import Link from '@/components/wiki-link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { apothecaryFirstUse } from '@/lib/apothecary-first-use';
import { anchorageFirstAnchor } from '@/lib/anchorage-first-anchor';
import { blacksmithFirstUse } from '@/lib/blacksmith-first-use';
import { recyclerFirstUse } from '@/lib/recycler-first-use';
import { surveyPostFirstUse } from '@/lib/survey-post-first-use';
import { serviceForSlug, serviceGuides } from '@/lib/services';

export function generateStaticParams() {
  return serviceGuides.map((guide) => ({ slug: guide.slug }));
}
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const guide = serviceForSlug(slug);
  return guide ? { title: guide.name, description: guide.summary } : {};
}
export default async function ServiceDetail({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const guide = serviceForSlug(slug);
  if (!guide) notFound();
  const station = content.stations.find(
    (entry) => entry.id === guide.stationID,
  );
  if (!station) notFound();
  const visualURL = station.assetURL ?? station.contextAssetURL;
  const visualLabel = station.assetURL
    ? `${station.name} building visual`
    : `${station.zone} town setting`;
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Village services', href: '/services' }, { label: guide.name }]} />
      <div className="entity-heading">
        {visualURL && (
          <PixelImage
            src={visualURL}
            alt={visualLabel}
            size={96}
          />
        )}
        <PageIntro
          eyebrow={station.zone}
          title={guide.name}
          summary={guide.summary}
        />
      </div>
      <p className="service-visual-note">{station.assetURL ? `The current retained building visual for ${station.name}.` : `The current retained ${station.zone} setting for this service.`}</p>
      <section className="article-section">
        <h2>Use it for</h2>
        <ul>
          {guide.useFor.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>
      <section className="article-section">
        <h2>Typical flow</h2>
        <ol className="numbered-guide">
          {guide.workflow.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </section>
      <section className="article-section">
        <h2>Choose the current entry</h2>
        <p>{guide.selection}</p>
      </section>
      <section className="article-section">
        <h2>What happens after you confirm</h2>
        <p>{guide.result}</p>
      </section>
      <section className="article-section">
        <h2>Worth remembering</h2>
        <div className="definition-grid">
          {guide.remember.map((item) => (
            <div key={item}>{item}</div>
          ))}
        </div>
      </section>
      {guide.slug === 'apothecary' && <section className="article-section"><h2>First remedy: Nessa to Lesser Salve</h2><p>Start this route only after <Link href="/people/nessa">Nessa</Link> has joined the Village. Her arrival reveals the foundation; recovering her diary pages or meeting another traveller does not replace that step.</p><ol className="numbered-guide">{apothecaryFirstUse.journey.map((step) => <li key={step}>{step}</li>)}</ol><div className="definition-grid"><div><h3>Build bundle</h3><p>{apothecaryFirstUse.construction}</p><p>Construction teaches Lesser Salve but grants no prepared item.</p></div><div><h3>First preparation</h3><p>{apothecaryFirstUse.firstRecipe}</p><p>The selected exact material and Resin are consumed only after preparation succeeds.</p></div></div><p><Link href="/places/apothecary">Review the Apothecary foundation</Link> · <Link href="/crafting/apothecary">Review current preparations</Link> · <Link href="/items/salve-lesser">Read Lesser Salve</Link></p></section>}
      {guide.slug === 'apothecary' && <section className="article-section two-column"><div><h2>Read the exact stock</h2><ul className="compact-list">{apothecaryFirstUse.shortfalls.map((line) => <li key={line}>{line}</li>)}</ul><p>{apothecaryFirstUse.inference}</p></div><div><h2>Keep these boundaries clear</h2><ul className="compact-list">{apothecaryFirstUse.boundaries.map((line) => <li key={line}>{line}</li>)}</ul><p>{apothecaryFirstUse.catalogueBoundary}</p></div></section>}
      {guide.slug === 'apothecary' && <section className="article-section note-card"><h2>Preparation costs are separate from construction</h2><ul className="compact-list">{apothecaryFirstUse.costs.map((line) => <li key={line}>{line}</li>)}</ul></section>}
      {guide.slug === 'blacksmith' && <section className="article-section"><h2>Third opening find: Halloway to Pointed Blade</h2><p>After <Link href="/people/halloway">Halloway</Link> joins the Village, her foundation appears in Home → Make. Her current request is: <em>“{blacksmithFirstUse.correctedRequest}”</em></p><ol className="numbered-guide">{blacksmithFirstUse.journey.map((step) => <li key={step}>{step}</li>)}</ol><p><Link href="/buildings/blacksmith">Review the Blacksmith foundation</Link> · <Link href="/crafting/blacksmith">Review Pointed Blade construction</Link> · <Link href="/systems/equipment-materials">Read equipment and material effects</Link></p></section>}
      {guide.slug === 'blacksmith' && <section className="article-section two-column"><div><h2>Pointed Blade stays specific</h2><ul className="compact-list">{blacksmithFirstUse.pointedBlade.map((line) => <li key={line}>{line}</li>)}</ul><p>{blacksmithFirstUse.stockBoundary}</p></div><div><h2>Reforge one exact piece</h2><ul className="compact-list">{blacksmithFirstUse.reforgeBoundary.map((line) => <li key={line}>{line}</li>)}</ul></div></section>}
      {guide.slug === 'blacksmith' && <section className="article-section note-card"><h2>Custody and relaunch</h2><ul className="compact-list">{blacksmithFirstUse.refusalAndRelaunch.map((line) => <li key={line}>{line}</li>)}</ul></section>}
      {guide.slug === 'anchorage' && <section className="article-section"><h2>First held realm: Tovin to Atlas Seam</h2><p>Recruit <Link href="/people/tovin">Tovin</Link> to reveal this foundation in Home → Realms. Its complete construction cost is <strong>{anchorageFirstAnchor.construction}</strong>; completion opens the portfolio and Anchor Frame construction, but gives no realm or Frame.</p><ol className="numbered-guide">{anchorageFirstAnchor.journey.map((step) => <li key={step}>{step}</li>)}</ol><p><Link href="/buildings/anchorage">Review the Anchorage foundation</Link> · <Link href="/crafting/anchorage">Review Anchor Frame construction</Link> · <Link href="/sites/atlas-seam">Read Atlas Seam</Link></p></section>}
      {guide.slug === 'anchorage' && <section className="article-section two-column"><div><h2>Frame custody stays exact</h2><ul className="compact-list">{anchorageFirstAnchor.frameCustody.map((line) => <li key={line}>{line}</li>)}</ul></div><div><h2>Confirm the current Seam</h2><ul className="compact-list">{anchorageFirstAnchor.seamConfirmation.map((line) => <li key={line}>{line}</li>)}</ul></div></section>}
      {guide.slug === 'anchorage' && <section className="article-section note-card"><h2>What the first anchor does not start</h2><ul className="compact-list">{anchorageFirstAnchor.firstRealm.map((line) => <li key={line}>{line}</li>)}</ul><h3>Relaunch boundary</h3><ul className="compact-list">{anchorageFirstAnchor.relaunch.map((line) => <li key={line}>{line}</li>)}</ul></section>}
      {guide.slug === 'recycler' && <section className="article-section"><h2>First use with Noll</h2><p>Recruit <Link href="/people/noll">Noll</Link>, then build the Recycler for <strong>{recyclerFirstUse.buildCost}</strong>. The completed bench previews recovery; it does not grant gear, resources, a recipe, or a Field Separation Kit.</p><div className="definition-grid"><div><h3>Honest empty state</h3><p>{recyclerFirstUse.emptyState}</p></div><div><h3>Before the irreversible choice</h3><p>{recyclerFirstUse.zeroOutput}</p></div></div><ul className="compact-list">{recyclerFirstUse.boundaries.map((line) => <li key={line}>{line}</li>)}</ul><p><Link href="/recycling">Read the Recycler return and protection reference</Link></p></section>}
      {guide.slug === 'survey-post' && <section className="article-section"><h2>First reading: Mara to Survey</h2><p>Recruit <Link href="/people/mara">Mara</Link> to reveal this foundation in Home → Study. Its complete construction cost is <strong>{surveyPostFirstUse.construction}</strong>; building it opens Field Instruments research but grants no instrument, material, observation, map disclosure, or field action.</p><ol className="numbered-guide">{surveyPostFirstUse.journey.map((step) => <li key={step}>{step}</li>)}</ol><p><Link href="/buildings/survey-post">Review the Survey Post foundation</Link> · <Link href="/crafting/instruments">Read Field Instruments</Link> · <Link href="/systems/field-supplies">Open the Field Kit guide</Link></p></section>}
      {guide.slug === 'survey-post' && <section className="article-section two-column"><div><h2>Eight permanent capabilities</h2><p>Studying any of these nodes grants its named subject at Crude precision. The displayed Research preview is the current cost authority; Mara’s current Home staffing can change only that future cost.</p><ul className="compact-list">{surveyPostFirstUse.instruments.map(([id, name, subject, cost]) => <li key={id}><strong>{name}</strong> · {subject} · {cost}</li>)}</ul></div><div><h2>Pack, then Survey</h2><ul className="compact-list">{surveyPostFirstUse.loadoutAndSurvey.map((line) => <li key={line}>{line}</li>)}</ul></div></section>}
      {guide.slug === 'survey-post' && <section className="article-section note-card"><h2>Relaunch, refusal, and improvement boundary</h2><ul className="compact-list">{surveyPostFirstUse.refusalAndRelaunch.map((line) => <li key={line}>{line}</li>)}</ul><h3>Precision improvement is not a promised purchase yet</h3><ul className="compact-list">{surveyPostFirstUse.improvementBoundary.map((line) => <li key={line}>{line}</li>)}</ul></section>}
      {guide.slug === 'library' && <section className="article-section note-card"><h2>People and records</h2><p>The Library helps you return to recovered records. The Player Wiki keeps each person’s complete current authored book pages together and separates location-hint stages with a clear spoiler boundary.</p><p><Link href="/people">Browse complete people records</Link></p></section>}
      <RelatedGuides links={[
        { label: 'All village services', href: '/services' },
        { label: `${station.name} construction and keeper`, href: `/places/${station.slug}` },
        ...guide.relatedGuides,
        ...(guide.slug === 'library' ? [{ label: 'People and complete records', href: '/people' }] : []),
        ...(guide.slug === 'trading-post' ? [{ label: 'Trading offer and sale terms', href: '/trading' }] : []),
        ...(guide.slug === 'recycler' ? [{ label: 'Recycler return reference', href: '/recycling' }] : []),
        ...(guide.slug === 'apothecary' ? [{ label: 'Nessa', href: '/people/nessa' }, { label: 'Apothecary construction', href: '/places/apothecary' }, { label: 'Apothecary preparations', href: '/crafting/apothecary' }, { label: 'Lesser Salve', href: '/items/salve-lesser' }] : []),
        ...(guide.slug === 'blacksmith' ? [{ label: 'Halloway', href: '/people/halloway' }, { label: 'Blacksmith construction', href: '/buildings/blacksmith' }, { label: 'Pointed Blade construction', href: '/crafting/blacksmith' }, { label: 'Equipment and material effects', href: '/systems/equipment-materials' }] : []),
        ...(guide.slug === 'anchorage' ? [{ label: 'Tovin', href: '/people/tovin' }, { label: 'Anchorage construction', href: '/buildings/anchorage' }, { label: 'Anchor Frame', href: '/crafting/anchorage' }, { label: 'Atlas Seam', href: '/sites/atlas-seam' }] : []),
        ...(guide.slug === 'recycler' ? [{ label: 'Noll', href: '/people/noll' }, { label: 'Recycler construction', href: '/buildings/recycler' }] : []),
        { label: 'All systems', href: '/systems' },
      ]} />
    </SiteFrame>
  );
}
