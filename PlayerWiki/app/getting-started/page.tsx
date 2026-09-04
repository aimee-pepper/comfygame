import { SeptemberDecisions } from '@/components/september-decisions';
import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { content } from '@/lib/content';
import { starterRuneFlow } from '@/lib/crafting-overview';

const steps = [
  ['Start or continue a campaign', 'A campaign book keeps your saved progress. Continue the newest book when returning to the game.'],
  ['Prepare in the Village', 'Review your party, equipment, Field Kit, research, and available station work before leaving home.'],
  ['Write a world', 'At the Writing Desk, choose a hand and ink, place and connect Sigils, review the World preview, then Bind.'],
  ['Enter and explore', 'The entry portal marks where you arrived. Reveal terrain, inspect adjacent places, collect resources, and search sites.'],
  ['Choose when to return', 'Return through an exit when you are ready. Defeat also ends the expedition, but not every carried item is guaranteed to come home.'],
  ['Use what came back', 'Review the expedition result, improve the Village and party, and write a different world for the next expedition.'],
];

export default function GettingStarted() {
  const firstSupply = content.items.find((item) => item.consumable && item.assetURL);

  return <SiteFrame sidebar><PageIntro eyebrow="Start here" title="Getting started" summary="Bookbinder alternates between preparing at home, writing a world, exploring it, and bringing discoveries back to strengthen the next expedition." />
    <SeptemberDecisions topic="progression" />
    <section className="article-section first-trip-visuals"><h2>Three things to recognise</h2><div className="journey-strip">
      <Link href="/systems/world-writing"><img src={content.writingAssetURL} alt="Writing Desk parchment" /><span><strong>Writing Desk</strong><small>Use the parchment workspace to shape the Page before Binding.</small></span></Link>
      <Link href="/systems/exploration"><img src={content.explorationVisuals.entryPortal} alt="Entry portal" /><span><strong>Entry portal</strong><small>Your arrival point remains marked as you explore the world.</small></span></Link>
      {firstSupply && <Link href={`/items/${firstSupply.slug}`}><PixelImage src={firstSupply.assetURL} alt={`${firstSupply.name} icon`} size={58} /><span><strong>Field supply</strong><small>Read the individual item entry before relying on it in the field.</small></span></Link>}
    </div></section>
    <section className="article-section"><h2>The core loop</h2><ol className="numbered-guide">{steps.map(([title, text]) => <li key={title}><span><strong>{title}</strong><p>{text}</p></span></li>)}</ol></section>
    <section className="article-section"><h2>The planned first Writing lesson</h2><TruthPair current={starterRuneFlow.current} accepted={starterRuneFlow.intended} acceptedLabel="Planned opening" /><p><strong>If the introduction is interrupted:</strong> {starterRuneFlow.recovery}</p><p><strong>Existing campaigns:</strong> {starterRuneFlow.legacy}</p></section>
    <section className="article-section two-column"><div><h2>Good first priorities</h2><ul><li>Read the current Page before changing it.</li><li>Carry at least one healing supply when possible.</li><li>Inspect unfamiliar terrain and flora before entering.</li><li>Keep track of the entry portal and revealed exits.</li><li>Return before instability or party health becomes unmanageable.</li></ul></div><div className="note-card"><h3>Your campaign keeps what matters</h3><p>Your campaign book saves the Cottage, party, knowledge, and everything successfully brought home. Each generated world may be temporary, but those lasting discoveries are not.</p></div></section>
    <nav className="next-links" aria-label="Continue reading"><Link href="/journey">Your current journey</Link><Link href="/actions">Action reference</Link><Link href="/systems/world-writing">Next: World Writing</Link><Link href="/systems/exploration">Exploration guide</Link></nav>
  </SiteFrame>;
}
