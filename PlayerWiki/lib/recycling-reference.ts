import { content } from '@/lib/content';

export const recyclerStation = content.stations.find(
  (station) => station.id === 'recycler',
);

export const authoredSalvageProfiles: Record<string, string[]> = {
  forged_edge_v1: ['ore', 'timber', 'ore'],
  headed_tool_v1: ['ore', 'timber', 'ore'],
  long_haft_v1: ['timber', 'ore', 'fiber'],
  board_guard_v1: ['timber', 'ore', 'fiber'],
  rigid_protection_v1: ['ore', 'fiber', 'ore'],
  padded_protection_v1: ['fiber', 'fiber', 'fiber'],
  boots_v1: ['fiber', 'fiber', 'timber'],
  keepsake_v1: ['pulp', 'fiber', 'quartz'],
};

export const standardRecyclerGear = content.items.filter(
  (item) =>
    Boolean(item.gear) &&
    item.recyclerDisposition === 'recyclable' &&
    item.salvageProfileID !== null &&
    item.salvageProfileID in authoredSalvageProfiles,
);

export function resourceName(resourceID: string) {
  return content.resources.find((resource) => resource.id === resourceID)?.name
    ?? resourceID;
}

export function recyclerOutputForTier(profileID: string, tier: number) {
  return (authoredSalvageProfiles[profileID] ?? []).slice(0, Math.max(0, Math.min(3, tier)));
}
