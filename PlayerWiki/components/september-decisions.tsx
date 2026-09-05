import Link from '@/components/wiki-link';

export type DecisionTopic = 'crafting' | 'progression' | 'exploration' | 'writing' | 'appearance' | 'people' | 'status';

const updates: Record<DecisionTopic, { current?: string; decided: string; tuning?: string; open?: string }> = {
  crafting: {
    decided: 'Starter Blacksmith gear uses raw materials, with no separate Ingot, Haft, or Cord step. The basic forge improves the stone Pick and Axe with iron working parts. Basic healing no longer requires Quartz. Blacksmith T2 makes Iron Ingots for a better Scythe and a reinforced woven garment. Corrin can make a useful plant-cloth garment, gloves and boots before Ingots or Leather, and expands the pack through Carry. An optional Leather path uses actual creature coverings and Salt. Earlier recipes remain usable after an upgrade.',
    tuning: 'The new starter blade and either tool improvement use 4 Iron, 1 Log, 2 Plant Fibre, and 1 Coal, with no Essence. Lesser Salve uses 1 Resin and 1 Plant Fibre. These are intended first-pass recipes, not current phone costs.',
    open: 'Refining an existing piece toward Peerless is being designed. The proposed Mote + maximum shop + attending keeper guarantee is not implemented; partial odds and Mote spending on a miss remain open. The old twentieth-copy rule is reopened.',
  },
  progression: {
    decided: 'Begin with a stone Pick, Axe, and Scythe in the dedicated tool roll. First Pick and Axe improvements belong at the basic forge. Healing must not depend on a later mineral upgrade. Nessa and Halloway can be discovered from the beginning; Bryn, Corrin, and Noll can follow after one recruit. Useful location clues can still reach ahead. The first two pack projects belong to the opening Storehouse; Corrin’s larger expansion follows. Pack capacity reaches 23, with Sela’s separate +2 taking it to 25. Recipes and costs remain revisable.',
    tuning: 'Apothecary: 20 Essence, 4 Clay, 4 Logs. Blacksmith: 20 Essence, 8 Iron, 4 Plant Fibre, 4 Logs. Starter Plant Fibre means Stem or Leaf Fibre; Logs mean Softwood or Hardwood. These are intended starting values, not installed costs.',
    open: 'The new early route still needs implementation and journey testing. T2 smelting and the first cloth/Leather specialist paths are specified; the wider campaign redesign remains separate work. Current directory order remains current behavior.',
  },
  exploration: {
    decided: 'A successful journey should usually leave worthwhile territory unexplored. Trees, canopy, and branching routes create choices without hiding required teaching or erasing earned minimap knowledge. There is no artificial reveal cap or routine full-map reward. Pinning a known recipe highlights useful sources as soon as normally visible, including new creatures, without prior inspection or a suitable tool. Random drops remain possible; fog and hidden rewards stay hidden. The accepted three-quarter view makes trunk-base Axe targeting clear and fades obstructing foreground art without granting extra sight.',
    open: 'The first test of 1,000 completely unwritten worlds found suitable growing land in only 3.6%, below the intended 25% review target. This early gathering problem is under investigation; a local soil-drainage correction remains a proposal. A correction preserving ordinary background root water is specified but unverified. The Sun-authored map, placed sources, travel and Stability still need verification. No universal map-completion percentage is fixed.',
  },
  writing: {
    decided: 'The intended opening teaches Illumination and Sun through a safe introductory excursion, then visibly connects the player’s first written choice to the world they bind. Unwritten features remain generated. Traveller clues use recognizable world facts and vocabulary the player has had a chance to learn; existing knowledge and Pages remain in older saves.',
    open: 'Early maker clues and the next water, River, ground, and Iron lessons are specified. Their delivery and pacing still need verification; the wider campaign order remains separate.',
  },
  appearance: {
    decided: 'Material colour is a worthwhile gathering goal. Every equipment component region receives its selected tint while keeping its silhouette and shading. Quality colours the name highlight and thumbnail border, not the item art; potions keep recognizable authored colours. World palettes stay stable, with separate foliage (including grass), water, and sky channels; an assigned shade takes precedence. Grass colour does not grant harvestability. Recipe tracking uses a thin soft pulsing outline, then a brief collection/completion sparkle.',
    open: 'Three-quarter top-down presentation, local water heights, clear trunk-base targeting, and foreground fade are decided. Exact artwork dimensions, composition, and fade timing await the bounded in-game proof. Final world-entry layer sizes, placement, and movement remain open. Aimee’s Library work is in progress; sky/cloud homework is optional study work.',
  },
  people: {
    decided: 'The intended priority is Vance, then Nessa and Halloway, then Bryn, Corrin, and Noll. Nessa is sought in fresh growing land, Halloway near workable Iron, and Corrin near fibre-bearing growth. Early makers no longer wait behind the old three-recruit requirement. Old clues keep their discovery value and receive updated hints.',
    open: 'This is an intended discovery priority, not a compulsory single-file sequence. Current character pages retain delivered behavior. The wider campaign redesign and actual early-route pacing remain separate work.',
  },
  status: {
    current: 'Ordinary consumable and physical-gear crafts now confirm success only after saving. A failed save refuses the craft without spending ingredients or granting the item. This correction is delivered and covered by focused tests; interactive crafting playthrough is still pending. The Binder and human Gambits/Training presentation update is also delivered, including clearer rule colours, capitalized labels, and the earned-automation explanation. The Apothecary recipe tiles, detail, and preparation presentation are now delivered too, with existing recipes and knowledge preserved.',
    decided: 'The wiki separates current behavior, decided intended behavior, unsettled proposals, and first-pass tuning. Today’s crafting, stone-tool, exploration, recipe-tracking, and colour decisions are intended changes. Costs and order can be revised.',
    open: 'Scent Mask and Seamlight can be prepared, but Field Kit use is unverified for the current phone build. The crafting correction covers ordinary consumable and physical-gear crafts, not every economy action or the overhaul. Interactive campaign playthrough and physical-phone visual acceptance of the Party and Apothecary presentation are still pending. Unlocks, existing entitlements, Training rules, and Gambit rules are unchanged.',
  },
};

export function SeptemberDecisions({ topic }: { topic: DecisionTopic }) {
  const update = updates[topic];
  return <section className="article-section note-card">
    <h2>4 September decisions</h2>
    <p><strong>Current behavior:</strong> {update.current ?? 'Sections labelled current describe the existing game. The intended changes recorded here are not yet verified as delivered.'}</p>
    <p><strong>Decided intended behavior:</strong> {update.decided}</p>
    {update.tuning && <p><strong>First-pass tuning:</strong> {update.tuning}</p>}
    {update.open && <p><strong>{topic === 'status' ? 'Verification pending' : 'Unsettled proposals and remaining work'}:</strong> {update.open}</p>}
    <p><Link href="/references/design-decisions-september-4">Read the complete decisions and early recipe tables</Link> · <Link href="/references/aimee-homework">Aimee Homework</Link></p>
  </section>;
}
