import SwiftUI

struct TutorialCard: View {
    let lesson: TutorialLessonDefinition
    let gotIt: () -> Void
    let notNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lesson.title).font(.headline)
            Text(lesson.body).font(.subheadline)
            Text(lesson.anchorLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
            HStack {
                Button("Not now", action: notNow)
                Spacer()
                Button("Got it", action: gotIt).buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.tint.opacity(0.35)))
        .shadow(radius: 8, y: 3)
        .accessibilityElement(children: .contain)
    }
}

struct FieldNotesView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        List {
            ForEach(TutorialLessonDefinition.Group.allCases, id: \.self) { group in
                Section(group.rawValue) {
                    ForEach(Array(TutorialRules.definitions.filter { $0.group == group }.enumerated()),
                            id: \.offset) { _, lesson in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(lesson.title).font(.headline)
                            Text(lesson.body).font(.subheadline).foregroundStyle(.secondary)
                            Button("Replay on its screen") { store.replayTutorial(lesson.id) }
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    if group == .worlds {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Reading the minimap").font(.headline)
                            Text("The minimap remembers revealed ground, known routes and landmarks. Empty fog does not tell you what is hidden there.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Field Notes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
