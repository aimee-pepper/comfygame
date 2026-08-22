import Foundation

/// Canonical player copy for earlier progression requirements. Callers provide resolved names so
/// missing catalogue data fails closed instead of making a locked node look like a root.
enum ProgressionRequirementPresentation {
    enum Noun: String, Sendable {
        case upgrade = "Upgrade"
        case skill = "Skill"
    }

    enum Relationship: Sendable {
        case all
        case any
    }

    static func requirement(noun: Noun, relationship: Relationship,
                            requiredIDs: [String], resolvedNames: [String]) -> String {
        guard requiredIDs.count == resolvedNames.count,
              resolvedNames.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return "Required \(noun.rawValue) information is unavailable."
        }
        guard !requiredIDs.isEmpty else { return "Requires no earlier \(noun.rawValue)." }
        guard resolvedNames.count > 1 else { return "Requires \(resolvedNames[0])." }

        switch relationship {
        case .all:
            return "Requires \(naturalList(resolvedNames, conjunction: "and"))."
        case .any:
            return "Requires any one of: \(naturalList(resolvedNames, conjunction: "or"))."
        }
    }

    static let capstoneRequirement =
        "Capstone requirement: learn a connected route of 7 earlier Skills in this tree, including this discipline’s Root, one Fundamental, one Development, and one Mastery."

    static func skillsLearned(_ count: Int) -> String {
        count == 1 ? "1 Skill learned" : "\(count) Skills learned"
    }

    static func pointsReady(_ count: Int) -> String {
        count == 1 ? "1 point ready" : "\(count) points ready"
    }

    private static func naturalList(_ values: [String], conjunction: String) -> String {
        if values.count == 2 { return "\(values[0]) \(conjunction) \(values[1])" }
        return values.dropLast().joined(separator: ", ") + ", \(conjunction) \(values.last!)"
    }
}
