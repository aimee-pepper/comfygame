export function normalizedWeights(weights, validIds = null) {
  const entries = Object.entries(weights ?? {}).filter(([id, value]) => Number(value) > 0 && (!validIds || validIds.has(id)));
  const total = entries.reduce((sum, [, value]) => sum + Number(value), 0);
  if (!total) return [];
  return entries.map(([id, value]) => ({ id, weight: Number(value) / total }));
}

export function blendPoint(point, weights, transforms, validIds = null) {
  const influences = normalizedWeights(weights, validIds);
  if (!influences.length) return { x: point.x, y: point.y };
  return influences.reduce((result, influence) => {
    const transformed = transforms(influence.id, point);
    result.x += transformed.x * influence.weight;
    result.y += transformed.y * influence.weight;
    return result;
  }, { x: 0, y: 0 });
}

export function interpolateKeyframes(keys, time) {
  if (!keys?.length) return 0;
  if (keys.length === 1 || time <= keys[0].time) return keys[0].rotation ?? 0;
  const last = keys.at(-1);
  if (time >= last.time) return last.rotation ?? 0;
  const rightIndex = keys.findIndex(key => key.time >= time), left = keys[rightIndex - 1], right = keys[rightIndex];
  if (left.interpolation === "held") return left.rotation ?? 0;
  let t = (time - left.time) / Math.max(Number.EPSILON, right.time - left.time);
  if (left.interpolation === "ease") t = t * t * (3 - 2 * t);
  return (left.rotation ?? 0) + ((right.rotation ?? 0) - (left.rotation ?? 0)) * t;
}

export function sampleClip(clip, time) {
  const duration = Math.max(0, clip?.duration ?? 0), localTime = clip?.loop && duration ? ((time % duration) + duration) % duration : Math.max(0, Math.min(time, duration));
  return Object.fromEntries(Object.entries(clip?.tracks ?? {}).map(([boneId, keys]) => [boneId, interpolateKeyframes([...keys].sort((a,b) => a.time-b.time), localTime)]));
}
