import Link from '@/components/wiki-link';

export function FloraWarningStatus() {
  return <section className="article-section note-card">
    <h2>Recognizing dangerous growth</h2>
    <p><strong>Current development behavior:</strong> The static Dangerous growth warning is implemented and tested in Simulator. It appears on first full sight of an actual harmful patch and disappears when that sight is lost. Ordinary plants of the same species and stale, removed or harmless patches remain unmarked.</p>
    <p><strong>Phone availability:</strong> Phone build 307 and the separately prepared 308 do not include this later update. Phone delivery and your visual acceptance remain pending.</p>
    <p><strong>Intended direction:</strong> Known harm should have a readable warning without depending on animation. Dedicated 2D flora animation is deferred during the 3D transition. Hidden or remembered-only patches must not gain new warning markers.</p>
    <p><strong>Decided behavior — awaiting phone delivery:</strong> You approved one static Dangerous growth marker from first full sight of an actual harmful contact/toxin patch, with no prior injury, learning or field-guide requirement. Ordinary plants of the same species, partly seen growth and stale or removed patches stay unmarked. The generic cue reveals no damage numbers, duration, yields or hidden creatures. Your decision is complete in <Link href="/references/aimee-homework">Aimee Homework</Link>; phone delivery is still pending.</p>
  </section>;
}
