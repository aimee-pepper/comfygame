export function TruthPair({
  current,
  accepted,
}: {
  current: string;
  accepted: string;
}) {
  return (
    <div className="truth-pair">
      <section className="truth-panel truth-panel-current">
        <p className="truth-label">Playable now</p>
        <p>{current}</p>
      </section>
      <section className="truth-panel truth-panel-accepted">
        <p className="truth-label">Approved for a future update</p>
        <p>{accepted}</p>
      </section>
    </div>
  );
}
