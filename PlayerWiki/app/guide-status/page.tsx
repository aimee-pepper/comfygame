import { SeptemberDecisions } from '@/components/september-decisions';
import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { acceptedChoices, correctionStatus, craftingFamilyStatus, laterDesignWork, openDecisionSummary, openDecisions } from '@/lib/player-guide-status';

export default function GuideStatusPage() {
  const statusHref = (slug: string) => slug === 'recycler' ? '/recycling' : `/crafting/${slug}`;
  return <SiteFrame sidebar>
    <PageIntro eyebrow="Honest status guide" title="What’s playable now—and what is changing" summary="Bookbinder is still growing. This page keeps current behavior separate from intended changes so a future recipe is never mistaken for one you can use today." />
    <SeptemberDecisions topic="status" />
    <section className="article-section"><h2>Crafting and processing</h2><p>Open a system for its complete current recipe table and planned design. Unfinished Game Design work and any choices that genuinely need Aimee are listed separately below.</p><div className="status-card-grid">{craftingFamilyStatus.map((entry) => <article className="status-card" key={entry.slug}><p className="status-pill">{entry.status}</p><h3><Link href={statusHref(entry.slug)}>{entry.name}</Link></h3><TruthPair current={entry.current} accepted={entry.accepted} /></article>)}</div></section>
    <section className="article-section"><h2>Corrections and planned work</h2><div className="definition-grid">{correctionStatus.map((entry) => <div key={entry.title}><p className="status-pill">{entry.label}</p><h3>{entry.title}</h3><p>{entry.body}</p></div>)}</div></section>
    <section className="article-section"><h2>Decisions already made</h2><div className="definition-grid">{acceptedChoices.map((entry) => <div key={entry.title}><h3>{entry.title}</h3><p>{entry.body}</p></div>)}</div></section>
    <section className="article-section"><h2>Game Design work still to finish</h2><div className="definition-grid">{laterDesignWork.map((entry) => <div key={entry.title}><h3>{entry.title}</h3><p>{entry.body}</p></div>)}</div></section>
    <section className="article-section note-card"><h2>Choices for Aimee</h2>{openDecisions.length === 0 ? <p>{openDecisionSummary}</p> : <><p>Everything not listed here is owned by the design and implementation passes above.</p>{openDecisions.map((entry) => <div key={entry.title}><h3>{entry.title}</h3><p>{entry.body}</p></div>)}</>}<p><Link href="/references/aimee-homework">Open Aimee Homework</Link></p></section>
  </SiteFrame>;
}
