import Link from '@/components/wiki-link';
import { PixelImage } from '@/components/pixel-image';

export type DirectoryLink = {
  href: string;
  name: string;
  imageURL?: string | null;
  imageAlt?: string;
};

export function DirectoryIndex({
  label,
  entries,
}: {
  label: string;
  entries: DirectoryLink[];
}) {
  return (
    <section className="article-section directory-index" aria-labelledby="directory-index-title">
      <div className="directory-index-heading">
        <div>
          <p className="eyebrow">Quick index</p>
          <h2 id="directory-index-title">{label}</h2>
          <p>Choose an icon or name for the full entry.</p>
        </div>
        <a href="#at-a-glance">Compare at a glance</a>
      </div>
      <nav className="directory-index-grid" aria-label={label}>
        {entries.map((entry) => (
          <Link className="directory-index-link" href={entry.href} key={entry.href}>
            {entry.imageURL ? (
              <PixelImage
                src={entry.imageURL}
                alt={entry.imageAlt ?? `${entry.name} icon`}
                size={38}
              />
            ) : (
              <span className="directory-index-monogram" aria-hidden="true">
                {entry.name.slice(0, 1)}
              </span>
            )}
            <span>{entry.name}</span>
          </Link>
        ))}
      </nav>
    </section>
  );
}

export function DirectoryDetailsIntro({
  title,
  summary,
}: {
  title: string;
  summary: string;
}) {
  return (
    <section className="article-section directory-details-intro" id="at-a-glance">
      <p className="eyebrow">At a glance</p>
      <h2>{title}</h2>
      <p>{summary}</p>
    </section>
  );
}
