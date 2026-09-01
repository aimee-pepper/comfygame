import { content, type GambitComponent } from '@/lib/content';

export type TechniqueReference = {
  id: string;
  slug: string;
  name: string;
  group: 'Technique' | 'Gambit subject' | 'Gambit condition' | 'Gambit threshold' | 'Gambit action';
  source: string;
  eligible: string;
  trigger: string;
  target: string;
  result: string;
  limits: string;
};

const slugify = (value: string) => value
  .toLowerCase()
  .replaceAll(/[^a-z0-9]+/g, '-')
  .replaceAll(/^-|-$/g, '');

const gambitGroup: Record<GambitComponent['kind'], TechniqueReference['group']> = {
  subject: 'Gambit subject',
  property: 'Gambit condition',
  comparator: 'Gambit condition',
  threshold: 'Gambit threshold',
  action: 'Gambit action',
};

const gambitTrigger: Record<GambitComponent['kind'], string> = {
  subject: 'When an enabled Gambit reaches this rule in its displayed top-to-bottom priority order.',
  property: 'When an enabled Gambit checks this condition in its displayed top-to-bottom priority order.',
  comparator: 'When an enabled Gambit compares its selected current value.',
  threshold: 'When an enabled Gambit needs the matching current threshold.',
  action: 'When the first enabled Gambit rule with a valid subject and condition is ready to act.',
};

const gambitTarget: Record<GambitComponent['kind'], string> = {
  subject: 'The subject named by this component.',
  property: 'The rule’s chosen subject.',
  comparator: 'The rule’s chosen subject and property.',
  threshold: 'The rule’s chosen subject and comparison.',
  action: 'The target selected by the complete valid rule.',
};

const gambitLimit: Record<GambitComponent['kind'], string> = {
  subject: 'The component must be owned by that party member. It does not choose a different subject if the named one is unavailable.',
  property: 'The component must be owned and paired with the required subject, comparison, and threshold when the rule needs them.',
  comparator: 'The component must be owned and paired with the required subject, property, and threshold.',
  threshold: 'The component must be owned and paired with the required subject, property, and comparison.',
  action: 'The component must be owned. A required technique must be ready and its target valid, or this rule does not fire and the next enabled rule can be considered.',
};

export const techniqueReferences: TechniqueReference[] = [
  ...content.combatTechniques.map((technique) => ({
    id: `technique-${slugify(technique.name)}`,
    slug: slugify(technique.name),
    name: technique.name,
    group: 'Technique' as const,
    source: technique.availability,
    eligible: technique.trainingRole ? `Only the party member who learned this Training node (depth ${technique.trainingDepth}) can use it.` : technique.availability,
    trigger: 'On that acting person’s turn, choose Techniques and select this option when it is shown Ready.',
    target: technique.target,
    result: technique.effect,
    limits: `${technique.cooldown}. There is no separate technique currency; a cooling technique or invalid target stays unavailable.`,
  })),
  ...content.gambitComponents.map((component) => ({
    id: `gambit-${component.kind}-${slugify(component.name)}`,
    slug: `gambit-${component.kind}-${slugify(component.name)}`,
    name: component.name,
    group: gambitGroup[component.kind],
    source: `An owned Gambit ${component.kind} component.`,
    eligible: 'Only the party member whose Gambit editor shows this owned component can use it in a rule; no gear grant is published for it.',
    trigger: gambitTrigger[component.kind],
    target: gambitTarget[component.kind],
    result: component.blurb,
    limits: gambitLimit[component.kind],
  })),
];

export const techniqueForSlug = (slug: string) => techniqueReferences.find((reference) => reference.slug === slug);
