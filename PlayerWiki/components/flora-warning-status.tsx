import Link from '@/components/wiki-link';

export function FloraWarningStatus() {
  return <section className="article-section note-card">
    <h2>Recognizing dangerous growth</h2>
    <p><strong>Current behavior:</strong> A dangerous patch is a specific hazard; other plants of the same species are not automatically harmful. Look can describe the patch. Aimee has reported that harmful flora is difficult to distinguish visually, and a corrected map warning has not been delivered for that report.</p>
    <p><strong>Intended direction:</strong> Known harm should have a readable warning without depending on animation. Dedicated 2D flora animation is deferred during the 3D transition. Hidden or remembered-only patches must not gain new warning markers.</p>
    <p><strong>Decided intended behavior — implementation assigned:</strong> You approved one static Dangerous growth marker from first full sight of an actual harmful contact/toxin patch, with no prior injury, learning or field-guide requirement. Ordinary plants of the same species, partly seen growth and stale or removed patches stay unmarked. The generic cue reveals no damage numbers, duration, yields or hidden creatures. Your decision is complete in <Link href="/references/aimee-homework">Aimee Homework</Link>; delivery is still pending.</p>
  </section>;
}
