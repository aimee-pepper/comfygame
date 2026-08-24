export function directSpeechSpans(text) {
  if (typeof text !== "string") return [];
  return [...text.matchAll(/“[^”]+”|"[^"]+"/g)].map(match => match[0]);
}

export function selectTravellerSpeech(meeting) {
  if (!meeting || typeof meeting !== "object" || !Array.isArray(meeting.questions)) return null;
  const opening = directSpeechSpans(meeting.opening);
  if (opening.length) return {sourceKey: "opening:last-direct-speech", text: opening.at(-1)};
  for (const exchange of meeting.questions) {
    const reply = directSpeechSpans(exchange?.reply);
    if (reply.length) return {sourceKey: `exchange:${exchange.id}:first-direct-speech`, text: reply[0]};
  }
  return null;
}

export function buildExactSpeechRows({effectiveMeetings, expectedRows, corpusFingerprint, hashMeeting}) {
  if (!Array.isArray(effectiveMeetings) || !Array.isArray(expectedRows)
    || typeof corpusFingerprint !== "string" || !corpusFingerprint
    || typeof hashMeeting !== "function") throw new Error("invalid-speech-receipt-builder-input");
  const expected = new Map(expectedRows.map(row => [row.travellerID, row]));
  const rows = effectiveMeetings.map(meeting => {
    const selected = selectTravellerSpeech(meeting), authority = expected.get(meeting.travellerID);
    if (!selected) throw new Error(`speech-source-missing:${meeting.travellerID}`);
    if (!authority || selected.sourceKey !== authority.sourceKey || selected.text !== authority.text) {
      throw new Error(`speech-authority-mismatch:${meeting.travellerID}`);
    }
    return {
      travellerID: meeting.travellerID,
      displayName: meeting.displayName,
      sourceKey: selected.sourceKey,
      text: selected.text,
      effectiveMeetingSHA256: hashMeeting(meeting),
      effectiveMeetingCorpusFingerprint: corpusFingerprint,
    };
  });
  if (rows.length !== expectedRows.length || new Set(rows.map(row => row.travellerID)).size !== rows.length
    || rows.some(row => !expected.has(row.travellerID))) throw new Error("speech-receipt-incomplete");
  return rows;
}
