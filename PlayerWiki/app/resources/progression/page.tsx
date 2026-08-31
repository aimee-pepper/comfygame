import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { recipesUsingResource } from '@/lib/crafting';

const bandOrder = ['Staple', 'Uncommon', 'Rare', 'Precious', 'Nontradeable'];

function buildingUses(resourceID: string) {
  return content.stations.filter((station) =>
    station.buildCost.some(
      (cost) => (cost.id ?? cost.resource ?? cost.resourceID) === resourceID,
    ),
  );
}

export default function ResourceProgressionPage() {
  return (
    <SiteFrame sidebar>
      <PageIntro
        eyebrow="Planning reference"
        title="Resource roles and progression"
        summary="Compare every current material by availability band and by the crafting and construction systems that consume it. This page describes the implemented game; proposed future progression will be labelled separately when approved."
      />
      {bandOrder.map((band) => {
        const resources = content.resources.filter(
          (resource) => resource.tradeBand === band,
        );
        return (
          <section className="article-section" key={band}>
            <h2>{band}</h2>
            <div className="table-wrap data-table">
              <table>
                <thead>
                  <tr>
                    <th aria-label="Image" />
                    <th>Resource</th>
                    <th>Craft recipes</th>
                    <th>Building recipes</th>
                    <th>World conditions</th>
                  </tr>
                </thead>
                <tbody>
                  {resources.map((resource) => {
                    const crafts = recipesUsingResource(resource.id);
                    const buildings = buildingUses(resource.id);
                    return (
                      <tr key={resource.id}>
                        <td>
                          <PixelImage
                            src={resource.assetURL}
                            alt={`${resource.name} inventory icon`}
                          />
                        </td>
                        <td>
                          <Link href={`/resources/${resource.slug}`}>
                            {resource.name}
                          </Link>
                        </td>
                        <td>
                          {crafts.length
                            ? `${crafts.length} — ${crafts
                                .slice(0, 2)
                                .map((recipe) => recipe.name)
                                .join(', ')}${crafts.length > 2 ? '…' : ''}`
                            : 'No documented craft recipe'}
                        </td>
                        <td>
                          {buildings.length
                            ? `${buildings.length} — ${buildings
                                .slice(0, 2)
                                .map((station) => station.name)
                                .join(', ')}${buildings.length > 2 ? '…' : ''}`
                            : 'Not currently a building material'}
                        </td>
                        <td>{resource.drivenBy}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </section>
        );
      })}
      <section className="article-section note-card">
        <h2>How to read this</h2>
        <p>
          A low consumer count is not automatically a flaw: a rare or
          nontradeable resource can support one distinctive late-game purpose.
          The useful question is whether its acquisition challenge and its
          result feel deliberate. Each resource page lists the exact current
          recipes and buildings so you can inspect that relationship directly.
        </p>
      </section>
      <nav className="next-links">
        <Link href="/resources">All resources</Link>
        <Link href="/crafting">Crafting systems</Link>
        <Link href="/places">Building costs</Link>
      </nav>
    </SiteFrame>
  );
}
