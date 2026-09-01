import type { ComponentPropsWithoutRef } from 'react';

const siteBasePath = (process.env.NEXT_PUBLIC_BASE_PATH ?? '').replace(/\/+$/, '');

export function wikiHref(href: string) {
  if (!siteBasePath || !href.startsWith('/') || href.startsWith(`${siteBasePath}/`)) {
    return href;
  }

  const hashIndex = href.indexOf('#');
  const hash = hashIndex >= 0 ? href.slice(hashIndex) : '';
  const pathAndQuery = hashIndex >= 0 ? href.slice(0, hashIndex) : href;
  const queryIndex = pathAndQuery.indexOf('?');
  const query = queryIndex >= 0 ? pathAndQuery.slice(queryIndex) : '';
  const pathname = queryIndex >= 0 ? pathAndQuery.slice(0, queryIndex) : pathAndQuery;

  if (pathname === '/') {
    return `${siteBasePath}/${query}${hash}`;
  }

  const pagePath = pathname.replace(/\/+$/, '');
  return `${siteBasePath}${pagePath}.html${query}${hash}`;
}

type WikiLinkProps = Omit<ComponentPropsWithoutRef<'a'>, 'href'> & {
  href: string;
};

export default function WikiLink({ href, children, ...props }: WikiLinkProps) {
  return <a href={wikiHref(href)} {...props}>{children}</a>;
}
