import cohesivePlan from '../../docs/resource-crafting-world-ecology-cohesive-plan-v1.md?raw';
import overhaulPlan from '../../docs/resource-crafting-world-overhaul-structure-v1.md?raw';
import implementationRoadmap from '../../docs/resource-crafting-world-implementation-roadmap-v1.md?raw';

export const designReferences = [
  {
    slug: 'resource-crafting-world-ecology-plan',
    title: 'Resource, Crafting, World, and Ecology Plan',
    summary: 'The organized intended player loop, material hierarchy, recipes, progression, ecology, world generation, and Wiki contract.',
    source: cohesivePlan,
  },
  {
    slug: 'resource-crafting-world-overhaul',
    title: 'Resource, Crafting, Creature, and World Overhaul Structure',
    summary: 'The system-by-system current foundation, intended structure, preserved behavior, structural work, and decisions still to discuss.',
    source: overhaulPlan,
  },
  {
    slug: 'resource-crafting-world-roadmap',
    title: 'Resource, Crafting, Creature, and World Implementation Roadmap',
    summary: 'The incremental vertical-slice rollout, migration rules, delivery gates, and complete player-journey destination.',
    source: implementationRoadmap,
  },
] as const;

export function designReferenceFor(slug: string) {
  return designReferences.find((reference) => reference.slug === slug);
}
