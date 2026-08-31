import Link from 'next/link';
import { Search } from 'lucide-react';
import type { ReactNode } from 'react';

const systemLinks = [
  ['/getting-started', 'Start here'],
  ['/systems', 'Systems overview'],
  ['/systems/world-writing', 'World Writing'],
  ['/systems/exploration', 'Exploration'],
  ['/systems/combat', 'Combat'],
  ['/bestiary', 'Bestiary records'],
  ['/systems/crafting', 'Crafting basics'],
];

const prepareLinks = [
  ['/crafting', 'Crafting systems'],
  ['/services', 'Village services'],
  ['/equipment', 'Equipment'],
  ['/consumables', 'Consumables'],
  ['/curios', 'Curios & key items'],
];

const referenceLinks = [
  ['/resources', 'Resources'],
  ['/people', 'People'],
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
          <Link href="/services">Village</Link>
          <Link href="/crafting">Crafting</Link>
          <Link href="/resources">Resources</Link>
          <Link href="/people">People</Link>
        </nav>
      </header>
      {sidebar ? (
        <div className="wiki-layout">
          <aside className="wiki-sidebar" aria-label="Wiki sections">
            <p>Learn</p>
            {systemLinks.map(([href, label]) => (
              <Link key={href} href={href}>
                {label}
              </Link>
            ))}
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
