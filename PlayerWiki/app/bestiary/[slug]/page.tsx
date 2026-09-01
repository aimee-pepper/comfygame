import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

export function generateStaticParams() { return content.creatures.map((creature) => ({ slug: creature.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const creature = content.creatures.find((entry) => entry.slug === slug);
  return creature ? { title: creature.name, description: `Current ${creature.name} encounter profile.` } : {};
}

export default async function BestiaryDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const creature = content.creatures.find((entry) => entry.slug === slug);
  if (!creature) notFound();
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Bestiary', href: '/bestiary' }, { label: creature.name }]} />
    <PageIntro eyebrow="Current encounter profile" title={creature.name} summary="A current named encounter profile. Your campaign’s Bestiary remains the source for whether you have encountered an individual specimen." />
    <section className="article-section"><h2>Combat profile</h2><dl className="fact-grid"><div><dt>Tier</dt><dd>{creature.tier}</dd></div><div><dt>Health</dt><dd>{creature.maxHP}</dd></div><div><dt>Attack</dt><dd>{creature.attack}</dd></div><div><dt>Notice range</dt><dd>{creature.sightRadius} tiles</dd></div><div><dt>Field profile</dt><dd>{creature.isNocturnal ? 'Night profile' : 'Day profile'}</dd></div><div><dt>Current status and drops</dt><dd>No separate fixed status or drop is published for this profile.</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>World conditions required</h2>{creature.requires.length ? <ul className="compact-list">{creature.requires.map((condition) => <li key={condition}>{condition}</li>)}</ul> : <p>No required world condition is currently listed.</p>}</div><div><h2>World conditions that help</h2>{creature.favours.length ? <ul className="compact-list">{creature.favours.map((condition) => <li key={condition}>{condition}</li>)}</ul> : <p>No additional helpful condition is currently listed.</p>}</div></section>
    <section className="article-section"><h2>Encounter and companionship</h2><p>Use the active encounter to read targets and current statuses. Attend applies only to an exact eligible visible animal; this profile does not promise companionship or disclose any individual’s trust state.</p><p><Link href="/systems/combat">Read Combat</Link> · <Link href="/systems/animals-companionship">Read Animals and companionship</Link></p></section>
    <RelatedGuides links={[{ label: 'All Bestiary profiles', href: '/bestiary' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'Site directory', href: '/sites' }, { label: 'Resources', href: '/resources' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Animals and companionship', href: '/systems/animals-companionship' }]} />
  </SiteFrame>;
}
