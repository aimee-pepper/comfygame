import type { Metadata } from 'next';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import homework from '../../../../docs/asset-homework-current.md?raw';

export const metadata: Metadata = {
  title: 'Asset Homework',
  description: "Aimee's running hand-authoring list: sky and cloud studies, Library books, and the specifications needed for final parallax assets.",
};

export default function AssetHomeworkPage() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Aimee Reference', href: '/references' }, { label: 'Asset Homework' }]} />
    <PageIntro eyebrow="Aimee Reference" title="Asset Homework" summary="Small pieces to draw whenever you have spare time. Start with a sky study; final export specifications will follow here." />
    <article className="article-section markdown-reference">
      <ReactMarkdown remarkPlugins={[remarkGfm]} components={{
        h1: () => null,
        table: ({ node: _node, ...props }) => <div className="table-wrap"><table {...props} /></div>,
      }}>{homework}</ReactMarkdown>
    </article>
    <RelatedGuides links={[
      { href: '/references', label: 'Aimee Reference' },
      { href: '/references/world-splash-assets', label: 'World Splash Asset Inventory' },
      { href: '/references/resource-world-numbers-decided-so-far', label: 'Settled world rules' },
    ]} />
  </SiteFrame>;
}
