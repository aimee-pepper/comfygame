import Link from '@/components/wiki-link';

export function DistilleryChannelworksOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Distillery and Channelworks first-pass plan</h2>
    <p><strong>Current behavior:</strong> direct attunement makes stored Cores using older property samples. Heat Cores can become stored fixtures; equipped combat housings are not yet delivered.</p>
    <p><strong>Decided intended behavior:</strong> three attunements across Close, Mid and Far reach, with permanent attunement and existing Burn, Poison or Dazzle. Light never illuminates the world. Oda’s one-time restored starter is separate from repeatable construction.</p>
    <p><strong>Design-authored first pass:</strong> complete named-material recipes, foundations, potency and attack values, all nine housings, retuning, reach changes and recovery. Existing Cores and owned fixtures retain their saved identities and potency. The replacement is pending implementation.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read every Core, housing, service and progression example</Link>.</p>
  </section>;
}
