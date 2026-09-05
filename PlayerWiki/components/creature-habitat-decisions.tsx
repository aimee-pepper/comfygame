import Link from '@/components/wiki-link';

export function CreatureHabitatDecisions() {
  return <section className="article-section note-card">
    <h2>Creature bodies and habitats</h2>
    <p><strong>Current development status:</strong> Physical habitat placement and the narrow Hide reward have development checks. Body-adapted generation and the wider flying movement below are not yet delivered to the phone.</p>
    <p><strong>Decided intended behavior:</strong> A creature’s body must suit its home. Land creatures stay on suitable ground. Shore creatures can use shallows and adjacent banks; a fish-shaped shore creature needs supporting limbs. Aquatic creatures stay in connected shallow and deep liquid water. Aerial creatures need membrane or feathered wings and may cross ground and water without a perch requirement.</p>
    <p>Flight does not let the party walk across deep water or pull an unreachable creature into combat. Trees, blocking deposits, chasms and crumbled gaps remain obstacles in this first slice. Ice is not liquid habitat. Existing worlds keep their creatures and movement.</p>
    <p><strong>Next material design:</strong> Plain Bone rewards, source history, Return and trading are specified for creatures with a qualifying internal skeleton. This is not implemented, and the new Bone still needs a compatible crafting update. Flying creatures do not automatically provide Hollow Bone; no new subtype or weapon recipe is approved.</p>
    <p><strong>Bestiary arrangement — decided:</strong> Sky, Water, Amphibious and Land, with body-shape subcategories: Four-legged, Two-legged, Serpentine, Segmented, Radial, Fish-shaped and Amorphous. Supported habitat chooses the section; Amphibious means water-and-land movement. Aimee approved this arrangement and lifted the Bestiary work hold on 5 September. Implementation is currently deferred while fresh-start early progression takes priority. The new arrangement is not yet implemented in the game.</p>
    <p><strong>Next ecology design:</strong> Role and movement descriptions must match the creature’s actual body and behavior. Membranes alone do not make a flier, weak weapons do not prove a grazing diet, and low bone density does not prove hollow bones. These naming changes are specified but not implemented; they add no new abilities or feeding simulation.</p>
    <p><strong>Remaining work:</strong> The wider creature rework, additional anatomical materials, and food, nesting and weather relationships remain unfinished. Existing Hide, Anatomy and source-colour decisions are preserved.</p>
    <p><Link href="/references/design-decisions-september-4">Read the habitat decisions and current development limits</Link></p>
  </section>;
}
