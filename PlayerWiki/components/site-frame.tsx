import Link from 'next/link';
import { Search } from 'lucide-react';
import type { ReactNode } from 'react';
import { playerStartGuides, systemGuideCategories } from '@/lib/system-guides';

const prepareLinks = [
  ['/crafting', 'Crafting systems'],
  ['/services', 'Village services'],
  ['/equipment', 'Equipment'],
  ['/consumables', 'Consumables'],
  ['/curios', 'Curios & key items'],
];

const referenceLinks = [
  ['/world', 'World reference'],
  ['/village', 'Village buildings'],
  ['/resources', 'Resources'],
  ['/trading', 'Trading offers'],
  ['/recycling', 'Recycler returns'],
  ['/bestiary', 'Bestiary records'],
  ['/sites', 'Site directory'],
  ['/statuses', 'Conditions & effects'],
  ['/techniques', 'Techniques & Gambits'],
  ['/actions', 'Action reference'],
  ['/people', 'People & records'],
  ['/places', 'Places & stations'],
  ['/glossary', 'Glossary'],
];

export function SiteFrame({
  children,
  sidebar = false,
}: {
  children: ReactNode;
  sidebar?: boolean;
}) {
  return (
    <div className="site-shell">
      <header className="site-header">
        <Link
          className="brand"
          href="/"
          aria-label="Bookbinder Player Wiki home"
        >
          <span className="brand-mark" aria-hidden="true">
            B
          </span>
          <span>
            <strong>Bookbinder</strong>
            <small>Player Wiki</small>
          </span>
        </Link>
        <form className="wiki-search" action="/search">
          <Search size={16} aria-hidden="true" />
          <input
            name="q"
            type="search"
            placeholder="Search the wiki"
            aria-label="Search the Player Wiki"
          />
        </form>
        <nav aria-label="Primary navigation">
          <Link href="/getting-started">Start here</Link>
          <Link href="/systems">Systems</Link>
          <Link href="/village">Village</Link>
          <Link href="/crafting">Crafting</Link>
          <Link href="/resources">Resources</Link>
          <Link href="/people">People</Link>
        </nav>
      </header>
      {sidebar ? (
        <div className="wiki-layout">
          <aside className="wiki-sidebar" aria-label="Wiki sections">
            <p>Learn</p>
            <Link href="/systems">Systems overview</Link>
            {playerStartGuides.map((guide) => <Link key={guide.href} href={guide.href}>{guide.label}</Link>)}
            {systemGuideCategories.map((category) => <div key={category.id} className="sidebar-guide-group"><p>{category.label}</p>{category.guides.map((guide) => <Link key={guide.href} href={guide.href}>{guide.label}</Link>)}</div>)}
            <p>Prepare</p>
            {prepareLinks.map(([href, label]) => (
              <Link key={href} href={href}>
                {label}
              </Link>
            ))}
            <p>Reference</p>
            {referenceLinks.map(([href, label]) => (
              <Link key={href} href={href}>
                {label}
              </Link>
            ))}
          </aside>
          <main className="wiki-main">{children}</main>
        </div>
      ) : (
        <main>{children}</main>
      )}
      <footer>
        <span>Bookbinder Player Wiki</span>
        <Link href="/glossary">Glossary</Link>
      </footer>
    </div>
  );
}
