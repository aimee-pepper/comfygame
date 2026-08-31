import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

export default function ResourcesPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Resources" summary="World resources are shaped by pressures in the Page and the world that Binding generates. Use this table to compare where each resource tends to appear and what it currently builds." />
    <div className="table-wrap data-table"><table><thead><tr><th aria-label="Image" /><th>Resource</th><th>Trade band</th><th>Mostly shaped by</th><th>Current uses</th></tr></thead><tbody>
      {content.resources.map(resource => <tr key={resource.id}><td><PixelImage src={resource.assetURL} alt={`${resource.name} inventory icon`} /></td><td><Link href={`/resources/${resource.slug}`}>{resource.name}</Link><small>{resource.summary}</small></td><td>{resource.tradeBand}</td><td>{resource.drivenBy}</td><td>{resource.currentUses.slice(0, 2).join(' ')}</td></tr>)}
    </tbody></table></div>
  </SiteFrame>;
}
