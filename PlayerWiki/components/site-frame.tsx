import Link, { wikiHref } from '@/components/wiki-link';
import { Menu, Search } from 'lucide-react';
import type { ReactNode } from 'react';
import { playerStartGuides, systemGuideCategories } from '@/lib/system-guides';
import { ThemeToggle } from '@/components/theme-toggle';

const prepareLinks = [
  ['/crafting', 'Crafting systems'],
  ['/services', 'Village services'],
  ['/equipment', 'Equipment'],
  ['/consumables', 'Consumables'],
  ['/curios', 'Curios & key items'],
];

const referenceLinks = [
  ['/references', 'Aimee Reference'],
  ['/guide-status', "What's playable now"],
  ['/loot', 'Loot & materials'],
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

const primaryLinks = [
  ['/getting-started', 'Start here'],
  ['/systems', 'Systems'],
  ['/village', 'Village'],
  ['/crafting', 'Crafting'],
  ['/resources', 'Resources'],
  ['/guide-status', "What's changing"],
  ['/people', 'People'],
  ['/references', 'Aimee Reference'],
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
        <div className="brand-tools">
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
          <ThemeToggle />
        </div>
        <form className="wiki-search" action={wikiHref('/search')}>
          <button
            className="wiki-search-submit"
            type="submit"
            aria-label="Search the Player Wiki"
          >
            <Search size={16} aria-hidden="true" />
          </button>
          <input
            name="q"
            type="search"
            placeholder="Search the wiki"
            aria-label="Search the Player Wiki"
          />
        </form>
        <nav className="desktop-navigation" aria-label="Primary navigation">
          {primaryLinks.map(([href, label]) => (
            <Link key={href} href={href}>
              {label}
            </Link>
          ))}
        </nav>
        <details className="mobile-navigation">
          <summary>
            <Menu size={17} aria-hidden="true" /> Browse the wiki
          </summary>
          <nav aria-label="Primary navigation">
            {primaryLinks.map(([href, label]) => (
              <Link key={href} href={href}>
                {label}
              </Link>
            ))}
          </nav>
        </details>
      </header>
      {sidebar ? (
        <div className="wiki-layout">
          <aside className="wiki-sidebar" aria-label="Wiki sections">
            <p>Learn</p>
            <Link href="/systems">Systems overview</Link>
            {playerStartGuides.map((guide) => (
              <Link key={guide.href} href={guide.href}>
                {guide.label}
              </Link>
            ))}
            {systemGuideCategories.map((category) => (
              <div key={category.id} className="sidebar-guide-group">
                <p>{category.label}</p>
                {category.guides.map((guide) => (
                  <Link key={guide.href} href={guide.href}>
                    {guide.label}
                  </Link>
                ))}
              </div>
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
        <Link href="/references">Aimee Reference</Link>
        <Link href="/glossary">Glossary</Link>
      </footer>
    </div>
  );
}
