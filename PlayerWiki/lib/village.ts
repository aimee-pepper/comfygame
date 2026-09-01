import { content, type Station } from '@/lib/content';
import { craftingSystems, recipesFor } from '@/lib/crafting';
import { serviceForStation } from '@/lib/services';

export const villageBuildings = [...content.stations, ...content.scheduledStations];

export function buildingForSlug(slug: string) {
  return villageBuildings.find((building) => building.slug === slug);
}

export function buildingStatus(building: Station) {
  return building.status === 'implemented' ? 'Current in game' : 'Scheduled · not implemented';
}

export function systemsForBuilding(building: Station) {
  return craftingSystems.filter((system) => system.station.includes(building.name));
}

export function buildingActions(building: Station) {
  const service = serviceForStation(building.id);
  const systems = systemsForBuilding(building);
  const recipes = systems.flatMap((system) => recipesFor(system.slug));
  return { service, systems, recipes };
}
