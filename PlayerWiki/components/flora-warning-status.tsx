import Link from '@/components/wiki-link';

export function FloraWarningStatus() {
  return <section className="article-section note-card">
    <h2>Recognizing dangerous growth</h2>
    <p><strong>Current behavior:</strong> the static Dangerous growth warning appears on first full sight of an actual harmful patch and disappears when that sight is lost. Ordinary plants of the same species and stale, removed or harmless patches remain unmarked.</p>
    <p><strong>Availability:</strong> delivered in build310, with installation and ordinary launch recorded. Final visual acceptance remains separate.</p>
    <p><strong>Intended direction:</strong> Known harm should have a readable warning without depending on animation. Dedicated 2D flora animation is deferred during the 3D transition. Hidden or remembered-only patches must not gain new warning markers.</p>
    <p><strong>Accepted rule:</strong> no prior injury, learning or field-guide entry is required. Partly seen growth stays unmarked. The generic cue reveals no damage numbers, duration, yields or hidden creatures. Your decision is complete in <Link href="/references/aimee-homework">Aimee Homework</Link>.</p>
  </section>;
}
