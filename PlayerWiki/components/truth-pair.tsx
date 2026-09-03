export function TruthPair({
  current,
  accepted,
  currentLabel = 'Playable now',
  acceptedLabel = 'Planned design',
}: {
  current: string;
  accepted: string;
  currentLabel?: string;
  acceptedLabel?: string;
}) {
  return (
    <div className="truth-pair">
      <section className="truth-panel truth-panel-current">
        <p className="truth-label">{currentLabel}</p>
        <p>{current}</p>
      </section>
      <section className="truth-panel truth-panel-accepted">
        <p className="truth-label">{acceptedLabel}</p>
        <p>{accepted}</p>
      </section>
    </div>
  );
}
