export function resetRouteScroll(windowObject, contentElement) {
  const position = { top: 0, left: 0, behavior: "instant" };
  windowObject.scrollTo(position);
  contentElement?.scrollTo?.(position);
}
