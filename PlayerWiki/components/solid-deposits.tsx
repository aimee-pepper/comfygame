import Link from '@/components/wiki-link';

export function SolidDeposits() {
  return <section className="article-section note-card">
    <h2>Solid deposits and mining</h2>
    <p><strong>Current behavior:</strong> blocking deposits and deliberate adjacent mining are implemented. Build357 restores normal resource generation for newly written ordinary3D worlds, including suitable Iron, Coal, Quartz, Sulfur, Mercury and Rift Glass deposits. Each world still follows its own conditions and source budget. Existing books retain their saved contents, including the earlier recording restrictions; earned stock and separate trial saves stay intact. A written Iron guarantee that cannot be fulfilled is refused before spending.</p>
    <p><strong>Decided preparation correction — not yet delivered:</strong> Every valid supported Page must make a playable world with its required sources on lawful separate tiles. Ordinary population targets must not cancel those sources; optional deposits gain no extra allowance. Current no-spend refusals protect your holdings while defects remain, but are not the accepted final outcome for valid Writing. Existing saved worlds keep their contents.</p>
    <p><strong>Decided intended behavior:</strong> Substantial deposits and boulders block their physical base. With the required packed Pick selected, deliberately step toward an adjacent harvestable deposit to mine it. A successful hit takes one world turn and keeps you beside it. The final hit clears its base; your next step enters the cleared square normally.</p>
    <p>A missing, wrong or insufficient tool spends no mining turn and takes no material. Automatic routes go around deposits or stop; they never mine or switch tools for you. Small loose stones, herbs and low gathering patches stay walkable, with their existing gathering or pickup actions.</p>
    <p>Deposits can create detours and opened shortcuts. The route home, starter resources and tool access stay protected, with a reachable place to stand beside required deposits. You will not need an Iron Pick to reach your only starter Iron. Deliberately tool-gated areas come later.</p>
    <p><Link href="/references/design-decisions-september-4">Read the full mining decision and early source rules</Link></p>
  </section>;
}
