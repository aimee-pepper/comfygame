import { content } from '@/lib/content';

const slugify = (value: string) => value
  .toLowerCase()
  .replaceAll(/[^a-z0-9]+/g, '-')
  .replaceAll(/^-|-$/g, '');

export const researchBranchFor = (id: string) =>
  content.researchBranches.find((branch) => branch.id === id);

export const researchNodeSlug = (node: (typeof content.researchNodes)[number]) => {
  const branch = researchBranchFor(node.branch);
  return `${slugify(branch?.name ?? node.branch)}-${slugify(node.name)}`;
};

export const researchNodeForSlug = (slug: string) =>
  content.researchNodes.find((node) => researchNodeSlug(node) === slug);

export const researchPrerequisiteNames = (node: (typeof content.researchNodes)[number]) => {
  const names = new Map(content.researchNodes.map((entry) => [entry.id, entry.name]));
  return node.requires.map((id) => names.get(id)).filter((name): name is string => Boolean(name));
};
