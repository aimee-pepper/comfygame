'use client';

import { useEffect } from 'react';
import Link, { wikiHref } from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';

export function VillageIndexRedirect({ formerTitle }: { formerTitle: string }) {
  const destination = wikiHref('/village');

  useEffect(() => {
    window.location.replace(destination);
  }, [destination]);

  return <SiteFrame sidebar>
    <meta httpEquiv="refresh" content={`0; url=${destination}`} />
    <PageIntro eyebrow="Village" title="One Village guide" summary={`${formerTitle} is now part of the complete Village page, so the same information is no longer split across competing overview pages.`} />
    <p><Link href="/village">Open the Village</Link></p>
  </SiteFrame>;
}
