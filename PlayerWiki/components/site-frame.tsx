import Link, { wikiHref } from '@/components/wiki-link';
import { Menu, Search } from 'lucide-react';
import type { ReactNode } from 'react';
import { ThemeToggle } from '@/components/theme-toggle';
import { primaryWikiLinks, wikiNavigationSections } from '@/lib/wiki-navigation';

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
          {primaryWikiLinks.map(({ href, label }) => (
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
            {primaryWikiLinks.map(({ href, label }) => (
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
            {wikiNavigationSections.map((section) => (
              <div key={section.label} className="sidebar-guide-group">
                <p>{section.label}</p>
                {section.links.map(({ href, label }) => (
                  <Link key={href} href={href}>
                    {label}
                  </Link>
                ))}
              </div>
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
