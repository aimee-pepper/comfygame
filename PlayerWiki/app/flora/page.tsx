import { WorldViewDirection } from '@/components/world-view-direction';
import { SeptemberDecisions } from '@/components/september-decisions';
import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { floraHarvestProfiles, resourcesFor } from '@/lib/world-reference';

export default function FloraDirectoryPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Field reference" title="Flora and harvesting" summary="Each visible plant has its own harvest. Use Look and Sela’s Field Guide to identify it instead of assuming that every patch of Tall Growth or Ground Cover gives the same resource." />
    <SeptemberDecisions topic="exploration" />
    <WorldViewDirection />
    <DirectoryIndex label="Browse Flora" entries={floraHarvestProfiles.map((flora) => { const resource = resourcesFor([flora.resultID])[0]; return { href: `/flora/${flora.slug}`, name: flora.name, imageURL: resource?.assetURL, imageAlt: resource ? `${resource.name} inventory icon` : undefined }; })} />
    <DirectoryDetailsIntro title="Compare harvest relationships" summary="These short cards identify the exact plant profile and its disclosed harvest relationship; the full entry keeps all current boundaries together." />
    <section className="article-section flora-directory">{floraHarvestProfiles.map((flora) => { const resource = resourcesFor([flora.resultID])[0]; return <Link className="flora-directory-card" href={`/flora/${flora.slug}`} key={flora.slug}>{resource?.assetURL && <PixelImage src={resource.assetURL} alt={`${resource.name} inventory icon`} size={44} />}<span><strong>{flora.name}</strong><small>{flora.summary}</small></span></Link>; })}</section>
    <section className="article-section note-card"><h2>Rules shared by Flora</h2><p>Looking changes nothing. Harvesting is a separate action against the exact current node. This directory describes current harvest relationships only; it never predicts an unseen plant, encounter, or entry result from appearance alone.</p></section>
  </SiteFrame>;
}
