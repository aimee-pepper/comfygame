import SwiftUI

/// Write a rule out of the parts you've learned.
///
/// You never buy a finished rule. You learn "Foe: lowest HP", and "30%", and "Skill", and then the
/// sentence is yours to write — which is why one new component is worth more than one new rule.
struct RuleBuilderView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let owner: Combatant

    @State private var subject: GambitComponentID?
    @State private var property: GambitComponentID?
    @State private var comparator: GambitComponentID?
    @State private var threshold: GambitComponentID?
    @State private var action: GambitComponentID?
    @State private var wantsCondition = false

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    // **"Who", not "Subject".** *Subject* is now the settled word for one of the
                    // eight things a world has (`vocabulary-settled.md`), and a rule's subject is a
                    // person or a creature — two meanings, two screens, one word. "Who" is clearer
                    // here anyway: a rule is about somebody.
                    picker("Who", kind: .subject, selection: $subject)

                    if store.canWriteConditions {
                        Toggle("Only if…", isOn: $wantsCondition.animation(.snappy))
                            .frame(minHeight: 44)
                        if wantsCondition {
                            picker("Property", kind: .property, selection: $property)
                            picker("Is", kind: .comparator, selection: $comparator)
                            picker("Than", kind: .threshold, selection: $threshold)
                        }
                    } else {
                        Text("You haven't learned to measure anything yet — a rule is simply *who → what they do* until you study a property, a comparator and a threshold.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Then") {
                    picker("Action", kind: .action, selection: $action)
                }

                Section {
                    Text(preview?.displayText ?? "Choose a subject and an action.")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(preview == nil ? .secondary : .primary)
                } header: {
                    Text("The rule")
                } footer: {
                    Text("Rules are checked top to bottom, and the first one that fits is the one that fires.")
                }
            }
            .navigationTitle("Write a rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        if let preview, store.addGambit(preview, for: owner) { dismiss() }
                    }
                    .disabled(preview == nil)
                }
            }
            .onAppear(perform: seedDefaults)
        }
    }

    /// Pre-fill with the first of everything you own, so the sheet opens on a valid sentence rather
    /// than four empty pickers.
    private func seedDefaults() {
        subject = subject ?? store.ownedComponents(.subject).first?.id
        action = action ?? store.ownedComponents(.action).first?.id
        property = property ?? store.ownedComponents(.property).first?.id
        comparator = comparator ?? store.ownedComponents(.comparator).first?.id
        threshold = threshold ?? store.ownedComponents(.threshold).first?.id
    }

    private var preview: GambitRule? {
        guard let subject, let action else { return nil }
        let useCondition = wantsCondition && store.canWriteConditions
        return GambitRule(
            id: InstanceID(rawValue: 0),
            subject: subject,
            property: useCondition ? property : nil,
            comparator: useCondition ? comparator : nil,
            threshold: useCondition ? threshold : nil,
            action: action
        )
    }

    @ViewBuilder
    private func picker(_ label: String,
                        kind: GambitComponentDef.Kind,
                        selection: Binding<GambitComponentID?>) -> some View {
        let options = store.ownedComponents(kind)
        Picker(label, selection: selection) {
            ForEach(options) { component in
                Label(component.name, systemImage: component.icon).tag(Optional(component.id))
            }
        }
        .frame(minHeight: 44)
        .disabled(options.isEmpty)
    }
}

#Preview {
    RuleBuilderView(owner: .companion(0))
        .environmentObject(GameStore(io: .temporary(name: "preview-rules")))
}
