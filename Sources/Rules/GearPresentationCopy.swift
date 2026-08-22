import Foundation

enum GearPresentationCopy {
    static func rarity(_ rarity: Rarity) -> String { rarity.rawValue.capitalisedSentence }
    static func damage(_ damage: DamageKind) -> String { damage.rawValue.capitalisedSentence }
    static func reach(_ reach: Reach) -> String { reach.rawValue.capitalisedSentence }
    static func piecesOfStock(_ count: Int) -> String {
        count == 1 ? "1 piece of stock" : "\(count) pieces of stock"
    }

    static func moreQualifyingPiecesOfStock(_ count: Int) -> String {
        count == 1 ? "1 more qualifying piece of stock" : "\(count) more qualifying pieces of stock"
    }

    static func physicalProtection(offset: Double) -> String {
        if offset == 0 { return "full physical protection" }
        let amount = abs(offset).formatted(.number.precision(.fractionLength(0...1)))
        return offset > 0
            ? "\(amount) more physical protection"
            : "\(amount) less physical protection"
    }

    static let olderSaveArtUnavailable = "From an older save. Detailed item art is unavailable."
}
