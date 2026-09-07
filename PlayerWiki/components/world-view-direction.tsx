import Link from '@/components/wiki-link';

export function WorldViewDirection() {
  return <section className="article-section note-card">
    <h2>Three-quarter world view</h2>
    <p><strong>Current behavior:</strong> The existing game remains the reference for movement, sight, and harvesting. The new view and foreground fading described here are intended changes, not a delivered visual update.</p>
    <p><strong>Decided intended behavior:</strong> Keep the square grid while showing the fronts and height of trees, rocks, characters, and cliffs.</p>
    <ul className="compact-list">
      <li>Water belongs to its local bed and surface height. A low river and a pond on raised land can coexist; shallow water can show its visible bed.</li>
      <li>Legal steps and slopes connect different heights. A cliff does not become a walkable route because its artwork overlaps another square.</li>
      <li>With an appropriate Axe selected, target the reachable trunk base. A small base highlight and “Chop tree” identify the action, and the impact lands at the trunk.</li>
      <li>Foreground art covering the character fades partly, keeping a faint silhouette and the already-visible blocking base. Only the obstructing cliff face fades, not the whole plateau.</li>
      <li>Fading preserves fog, gameplay canopy concealment, and earned minimap knowledge. It exposes only the character and surroundings the game already allows you to see.</li>
    </ul>
    <p><strong>Accepted for later, low priority:</strong> Trees, elevated land, bushes, resource nodes, and the player character should have shadows. Their treatment follows the new geometry and foreground visibility, behind the playable overhaul. Dynamic lighting and a day/night system are not part of this decision.</p>
    <p><strong>Ordinary 3D trial — current in build327:</strong> Settings → Owner Tools → 3D Trials offers one normally generated expedition with its own saved test state, using the current starting setup and normal costs. North stays up and east stays right in the square-projected three-quarter view. Ordinary 2D stays available; placeholders are allowed. Existing movement, tools, encounters, visibility, memory and fading remain authoritative.</p>
    <p>The supplied Simulator check used one generated expedition: north, south, normal portal Return after two turns, then one restart into the same saved Home. Purple creature placeholders were visible; combat and usable harvesting were not encountered. The phone update is installed and its trial remains fresh for you. This does not establish phone performance or full 3D readiness. Wider creature proposals and the unfinished zero-rune introduction are not prerequisites.</p>
    <p><strong>Build328 marker update:</strong> visible creatures now use rounded purple placeholders. These are neutral markers, not species artwork or material colours. The isolated marker check adds no expedition or phone-performance evidence.</p>
    <p><strong>Build329 corrections:</strong> 3D tiles match the displayed 2D tile size, and opaque trees covering the player’s body or occupied tile participate in the existing fade, including remembered trees. The wood-colour trial menu entry is removed. Build330 now fills the normal Explore viewport at that same tile size, preserving clipping and knowledge limits. Installation and ordinary launch succeeded; supplied movement/reopen checks are Simulator evidence, with your visual acceptance still separate.</p>
    <p><strong>Approved water study — implementation pending:</strong> You approved a separate, clearly labelled example scene showing a raised shallow pond and a lower channel with their own water levels. It uses chosen example heights because existing saves lack measured water depths. Campaigns keep their current rules, and a visible surface reveals only a permitted bed. The decision is complete in <Link href="/references/aimee-homework">Aimee Homework</Link>; the existing-world camera trial continues alongside it.</p>
    <p><strong>Still to be worked out:</strong> Exact artwork sizes, composition, and fade timing follow a bounded in-game proof. This does not add stacked bridge floors or change saved worlds.</p>
    <p><Link href="/references/design-decisions-september-4">Read the complete world-view and exploration decisions</Link></p>
  </section>;
}
