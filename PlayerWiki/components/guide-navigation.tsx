import Link from 'next/link';

type GuideLink = { label: string; href?: string };

export function GuideBreadcrumbs({ items }: { items: GuideLink[] }) {
  return <nav className="guide-breadcrumbs" aria-label="Breadcrumb">{items.map((item, index) => <span key={`${item.label}-${index}`}>{index ? <span aria-hidden="true"> / </span> : null}{item.href ? <Link href={item.href}>{item.label}</Link> : <span aria-current="page">{item.label}</span>}</span>)}</nav>;
}

export function RelatedGuides({ links }: { links: GuideLink[] }) {
  return <nav className="related-guides" aria-label="Related guides"><span>Related guides</span>{links.map((link) => <Link href={link.href ?? '/systems'} key={link.href ?? link.label}>{link.label}</Link>)}</nav>;
}
