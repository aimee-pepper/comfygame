import { GuideBreadcrumbs } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import {
  countScreenAuthoringStatuses,
  screenAuthoringLabels,
  screenAuthoringTree,
  type ScreenAuthoringNode,
  type ScreenAuthoringStatus,
} from '@/lib/screen-authoring-map';
import styles from './screen-authoring-map.module.css';

const statuses: ScreenAuthoringStatus[] = ['aimee', 'updated', 'in-progress', 'default'];

function ScreenNode({ node, depth = 0 }: { node: ScreenAuthoringNode; depth?: number }) {
  const body = <div className={`${styles.card} ${styles[node.status]}`}>
    <div className={styles.cardHeading}>
      <strong>{node.title}</strong>
      <span className={styles.status}>{screenAuthoringLabels[node.status]}</span>
    </div>
    {node.note ? <small>{node.note}</small> : null}
  </div>;

  if (!node.children?.length) return <li className={styles.node}>{body}</li>;
  return <li className={styles.node}>
    <details open={depth < 3}>
      <summary>{body}</summary>
      <ul className={styles.branch}>
        {node.children.map((child) => <ScreenNode node={child} depth={depth + 1} key={`${node.title}-${child.title}`} />)}
      </ul>
    </details>
  </li>;
}

export default function ScreenAuthoringMapPage() {
  const counts = countScreenAuthoringStatuses();
  const total = Object.values(counts).reduce((sum, count) => sum + count, 0);

  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[
      { label: 'Home', href: '/' },
      { label: 'Aimee Reference', href: '/references' },
      { label: 'Screen authoring map' },
    ]} />
    <PageIntro
      eyebrow="Production reference"
      title="Screen Authoring Map"
      summary="The current player-facing route tree, colour-coded by how far each screen has moved beyond its default UI. Expand any branch to see its child screens."
    />

    <section className={styles.legend} aria-label="Screen authoring status legend">
      {statuses.map((status) => <div className={`${styles.legendItem} ${styles[status]}`} key={status}>
        <strong>{counts[status]}</strong>
        <span>{screenAuthoringLabels[status]}</span>
      </div>)}
      <p>{total} tracked screens and screen-level states. “Partial or asset-ready” does not mean the UI is implemented.</p>
    </section>

    <section className="article-section" aria-labelledby="screen-tree-heading">
      <div className={styles.sectionHeading}>
        <div>
          <h2 id="screen-tree-heading">In-game screen tree</h2>
          <p>Districts and locked stations stay visible here so unfinished UI cannot disappear from the count.</p>
        </div>
        <span>Party updated 4 September 2026</span>
      </div>
      <ul className={`${styles.branch} ${styles.root}`}>
        {screenAuthoringTree.map((node) => <ScreenNode node={node} key={node.title} />)}
      </ul>
    </section>

    <section className="article-section note-card" aria-labelledby="how-to-read-heading">
      <h2 id="how-to-read-heading">How to read this tracker</h2>
      <p><strong>Aimee authored</strong> means Aimee supplied or directly authored the defining composition. <strong>Asset / Engineering updated</strong> means the current native consumer has an implemented UI pass. <strong>Partial or asset-ready</strong> covers active corrections, mixed old/new surfaces, or artwork awaiting Engineering. <strong>Default / legacy UI</strong> means the accessible screen still needs a production UI pass.</p>
      <p>This records presentation progress only. “Updated” does not mean visual acceptance is complete or an ability is unlocked. Party delivery status was refreshed on 4 September; other branches retain the 2 September inventory. The latest human Gambits/Training update preserves existing rules and entitlements; interactive phone review and visual acceptance remain pending.</p>
    </section>
  </SiteFrame>;
}
