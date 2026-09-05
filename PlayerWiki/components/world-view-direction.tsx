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
    <p><strong>Still to be worked out:</strong> Exact artwork sizes, composition, and fade timing follow a bounded in-game proof. This does not add stacked bridge floors or change saved worlds.</p>
    <p><Link href="/references/design-decisions-september-4">Read the complete world-view and exploration decisions</Link></p>
  </section>;
}
