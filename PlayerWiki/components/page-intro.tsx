import type { ReactNode } from 'react';

export function PageIntro({ eyebrow, title, summary, children }: { eyebrow: string; title: string; summary: string; children?: ReactNode }) {
  return <header className="article-intro"><p className="eyebrow">{eyebrow}</p><h1>{title}</h1><p className="lede">{summary}</p>{children}</header>;
}
