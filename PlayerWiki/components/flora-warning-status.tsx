import Link from '@/components/wiki-link';

export function FloraWarningStatus() {
  return <section className="article-section note-card">
    <h2>Recognizing dangerous growth</h2>
    <p><strong>Current behavior:</strong> A dangerous patch is a specific hazard; other plants of the same species are not automatically harmful. Look can describe the patch. Aimee has reported that harmful flora is difficult to distinguish visually, and a corrected map warning has not been delivered for that report.</p>
    <p><strong>Intended direction:</strong> Known harm should have a readable warning without depending on animation. Dedicated 2D flora animation is deferred during the 3D transition. Hidden or remembered-only patches must not gain new warning markers.</p>
    <p><strong>Proposed:</strong> One small static marker on the actual dangerous patch. Whether it appears on first full sight or requires prior learning or field-guide recognition is an open decision in <Link href="/references/aimee-homework">Aimee Homework</Link>. The recommendation is first full sight; it would reveal no damage numbers, yields or hidden creatures.</p>
  </section>;
}
