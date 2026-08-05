import Foundation

/// One rule in a gambit list, **assembled from components you've learned**.
///
/// `subject [property comparator threshold] → action`, where the middle is optional. So
/// "Foe: any → Attack" is a subject and an action, while "Ally: any, health below 30% → Heal" uses
/// all five. Nothing here is a canned rule — every one is composed, which is why learning a single
/// new threshold multiplies with every subject and action you already have.
struct GambitRule: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var subject: GambitComponentID
    var property: GambitComponentID?
    var comparator: GambitComponentID?
    var threshold: GambitComponentID?
    var action: GambitComponentID

    /// A condition is all-or-nothing: you can't compare without something to compare against.
    var hasCondition: Bool { property != nil && comparator != nil && threshold != nil }

    /// Whether every part is a component the player actually owns. Guards against a rule that
    /// outlives the content or the ownership that made it legal.
    func isWritable(with owned: Set<GambitComponentID>) -> Bool {
        var parts = [subject, action]
        if let property { parts.append(property) }
        if let comparator { parts.append(comparator) }
        if let threshold { parts.append(threshold) }
        return parts.allSatisfy { owned.contains($0) && ContentCatalog.shared.gambitComponent($0) != nil }
    }

    /// "Foe: lowest HP · health below 30% → Attack"
    var displayText: String {
        let catalog = ContentCatalog.shared
        let subjectName = catalog.gambitComponent(subject)?.name ?? subject.rawValue
        let actionName = catalog.gambitComponent(action)?.name ?? action.rawValue

        guard hasCondition,
              let property, let comparator, let threshold,
              let propertyName = catalog.gambitComponent(property)?.name,
              let comparatorName = catalog.gambitComponent(comparator)?.name,
              let thresholdName = catalog.gambitComponent(threshold)?.name
        else { return "\(subjectName) → \(actionName)" }

        return "\(subjectName) · \(propertyName) \(comparatorName) \(thresholdName) → \(actionName)"
    }
}
