import type { CastPerson, Station } from '@/lib/content';

function comparableName(value: string) {
  return value
    .toLocaleLowerCase()
    .replace(/^the\s+/, '')
    .replace(/[’]/g, "'")
    .trim();
}

export function stationForPerson(person: CastPerson, stations: Station[]) {
  const role = comparableName(person.role);
  return stations.find((station) => role.includes(comparableName(station.name)));
}
