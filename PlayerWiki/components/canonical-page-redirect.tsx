'use client';

import { useEffect } from 'react';
import Link, { wikiHref } from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';

export function CanonicalPageRedirect({ formerTitle, href, label }: { formerTitle: string; href: string; label: string }) {
  const destination = wikiHref(href);

  useEffect(() => {
    window.location.replace(destination);
  }, [destination]);

  return <SiteFrame sidebar>
    <meta httpEquiv="refresh" content={`0; url=${destination}`} />
    <PageIntro eyebrow="Player Wiki" title={label} summary={`${formerTitle} is now part of this complete guide instead of being repeated on a competing overview page.`} />
    <p><Link href={href}>Open {label}</Link></p>
  </SiteFrame>;
}
