#if DEBUG
import SwiftUI
import UIKit

enum DebugBugReporterPlacementPolicy {
    static func verticalRange(height: CGFloat, safeTop: CGFloat, safeBottom: CGFloat,
                              isBase: Bool, reservesTopChrome: Bool = false) -> ClosedRange<CGFloat> {
        let safeMinimum = safeTop + 28
        let safeMaximum = height - safeBottom - 28
        if !isBase, reservesTopChrome {
            let lower = min(safeMaximum, max(safeMinimum, height * 0.48))
            let upper = max(lower, min(safeMaximum, height * 0.78))
            return lower...upper
        }
        guard isBase else { return safeMinimum...safeMaximum }
        let lower = min(safeMaximum, max(safeMinimum, height * 0.65))
        let upper = max(lower, min(safeMaximum, height * 0.78))
        return lower...upper
    }
}

struct DebugBugReporterOverlay: View {
    @ObservedObject var store: GameStore
    var route: AppRoute = .base
    @AppStorage("debug.reporter.x") private var savedX = 0.92
    @AppStorage("debug.reporter.y") private var savedY = 0.18
    @State private var isCapturing = false
    @State private var draft: DebugBugReportDraft?

    var body: some View {
        GeometryReader { proxy in
            if !isCapturing {
                Button {
                    capture(from: proxy)
                } label: {
                    Image(systemName: "ladybug.fill")
                        .font(.title3)
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.red.opacity(0.65), lineWidth: 1.5))
                }
                .foregroundStyle(.red)
                .accessibilityLabel("Report Bug")
                .accessibilityHint("Captures the current game screen, then opens a bug report form")
                .position(x: clamped(CGFloat(savedX) * proxy.size.width,
                                     proxy.safeAreaInsets.leading + 28,
                                     proxy.size.width - proxy.safeAreaInsets.trailing - 28),
                          y: clamped(CGFloat(savedY) * proxy.size.height,
                                     minimumY(in: proxy), maximumY(in: proxy)))
                .highPriorityGesture(DragGesture().onChanged { value in
                    savedX = Double(clamped(value.location.x / max(1, proxy.size.width), 0.08, 0.92))
                    savedY = Double(clamped(value.location.y / max(1, proxy.size.height), 0.08, 0.92))
                })
            }
        }
        .sheet(item: $draft) { draft in
            DebugBugReportSheet(draft: draft)
        }
    }

    private func capture(from proxy: GeometryProxy) {
        isCapturing = true
        DispatchQueue.main.async {
            let screenshot = DebugAppScreenshot.capture()
            draft = DebugBugReportDraft(screenshot: screenshot, context: context())
            isCapturing = false
        }
    }

    private func context() -> DebugBugReportContext {
        let run = store.state.worlds.activeRun
        return DebugBugReportContext(
            screen: store.activeEncounter != nil ? "encounter" : (run == nil ? "base" : "world"),
            route: store.activeEncounter != nil ? AppRoute.encounter.rawValue
                : (run == nil ? route.rawValue : AppRoute.world.rawValue),
            campaignReference: store.diagnosticCampaignReference,
            encounterID: store.activeEncounter?.id.rawValue,
            debugTuningSnapshot: Self.debugTuningSnapshot(),
            saveSchemaVersion: store.state.schemaVersion,
            mutationCount: store.state.meta.mutationCount,
            lastAction: store.state.meta.lastAction,
            semanticActionTrail: store.state.meta.semanticActionTrail,
            runIndex: run?.runIndex, mapSeed: run?.mapSeed,
            playerX: run?.playerPosition.x, playerY: run?.playerPosition.y,
            stability: run?.effectiveStabilityScore,
            outcomeID: store.state.worlds.lastExit?.outcomeID?.rawValue)
    }

    private func clamped(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }

    private func minimumY(in proxy: GeometryProxy) -> CGFloat {
        verticalRange(in: proxy).lowerBound
    }

    private func maximumY(in proxy: GeometryProxy) -> CGFloat {
        verticalRange(in: proxy).upperBound
    }

    private func verticalRange(in proxy: GeometryProxy) -> ClosedRange<CGFloat> {
        // Base reserves its upper band for purse + district tabs and its lower band for Depart.
        DebugBugReporterPlacementPolicy.verticalRange(
            height: proxy.size.height, safeTop: proxy.safeAreaInsets.top,
            safeBottom: proxy.safeAreaInsets.bottom, isBase: route == .base,
            reservesTopChrome: route != .world && route != .encounter
                && route != .settings && route != .harness
        )
    }

    private static func debugTuningSnapshot() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(DebugTuningProfile.active) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

private struct DebugBugReportContext {
    var screen: String
    var route: String?
    var campaignReference: String?
    var encounterID: UInt64?
    var debugTuningSnapshot: String?
    var saveSchemaVersion: Int
    var mutationCount: Int
    var lastAction: String
    var semanticActionTrail: [String]
    var runIndex: Int?
    var mapSeed: UInt64?
    var playerX: Int?
    var playerY: Int?
    var stability: Int?
    var outcomeID: UInt64?
}

private struct DebugBugReportDraft: Identifiable {
    let id = UUID()
    var screenshot: DebugAppScreenshot?
    var context: DebugBugReportContext
}

private struct DebugAppScreenshot {
    var png: Data
    var image: UIImage
    var width: Int
    var height: Int
    var scale: Double

    @MainActor static func capture() -> Self? {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: \.isKeyWindow) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        guard let png = image.pngData() else { return nil }
        return Self(png: png, image: image, width: image.cgImage?.width ?? 0,
                    height: image.cgImage?.height ?? 0, scale: window.screen.scale)
    }
}

private struct DebugBugReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let draft: DebugBugReportDraft
    @State private var whatHappened = ""
    @State private var expected = ""
    @State private var includeScreenshot = true
    @State private var savedPackage: URL?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if includeScreenshot, let screenshot = draft.screenshot {
                    Section("Captured before this form opened") {
                        Image(uiImage: screenshot.image).resizable().scaledToFit()
                            .accessibilityLabel("Captured game screenshot")
                        Toggle("Include screenshot", isOn: $includeScreenshot)
                    }
                } else if draft.screenshot != nil {
                    Section { Toggle("Include screenshot", isOn: $includeScreenshot) }
                } else {
                    Section { Text("Screenshot capture failed. Your text can still be saved.").foregroundStyle(.secondary) }
                }
                Section("What happened?") {
                    TextEditor(text: $whatHappened).frame(minHeight: 110)
                        .accessibilityLabel("What happened?")
                        .accessibilityIdentifier("bug-report.what-happened")
                }
                Section("What did you expect? (optional)") {
                    TextEditor(text: $expected).frame(minHeight: 72)
                        .accessibilityLabel("What did you expect? Optional")
                }
                Section("Captured context") {
                    LabeledContent("Roadmap checkpoint", value: DebugRoadmap.current.installedCheckpoint)
                    LabeledContent("Mode", value: draft.context.screen)
                    if let route = draft.context.route { LabeledContent("Screen", value: route) }
                    if let campaign = draft.context.campaignReference {
                        LabeledContent("Campaign", value: campaign)
                    }
                    if let encounter = draft.context.encounterID {
                        LabeledContent("Encounter", value: "\(encounter)")
                    }
                    if let tuning = draft.context.debugTuningSnapshot {
                        LabeledContent("DEBUG tuning") {
                            Text(tuning).font(.caption.monospaced()).textSelection(.enabled)
                        }
                    }
                    if !draft.context.semanticActionTrail.isEmpty {
                        LabeledContent("Recent actions") {
                            Text(draft.context.semanticActionTrail.joined(separator: " → "))
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                    LabeledContent("Save schema", value: "\(draft.context.saveSchemaVersion)")
                    if let run = draft.context.runIndex { LabeledContent("Expedition", value: "\(run)") }
                    Text("Build, game mode, save schema, expedition identifiers, world position, Stability and most recent saved action. No account data or save contents.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let savedPackage {
                    Section {
                        Label("Saved on this phone — not yet shared", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        ShareLink(item: exportedFile(in: savedPackage)) { Label("Share report package", systemImage: "square.and.arrow.up") }
                    }
                }
                if !DebugBugReportOutbox.live.reports().isEmpty {
                    Section("Saved reports") {
                        NavigationLink("Open bug queue") { DebugBugReportQueueView() }
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Report a bug")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(savedPackage == nil ? "Save" : "Done") {
                        if savedPackage == nil { save() } else { dismiss() }
                    }.disabled(savedPackage == nil && whatHappened.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let info = Bundle.main.infoDictionary ?? [:]
        let screenshot = includeScreenshot ? draft.screenshot : nil
        var report = DebugBugReport(
            id: draft.id, createdAt: Date(), whatHappened: whatHappened,
            expected: expected, includesScreenshot: screenshot != nil,
            screenshotWidth: screenshot?.width, screenshotHeight: screenshot?.height,
            screenshotScale: screenshot?.scale,
            appVersion: info["CFBundleShortVersionString"] as? String ?? "unknown",
            build: info["CFBundleVersion"] as? String ?? "unknown",
            screen: draft.context.screen, saveSchemaVersion: draft.context.saveSchemaVersion,
            mutationCount: draft.context.mutationCount, lastAction: draft.context.lastAction,
            runIndex: draft.context.runIndex, mapSeed: draft.context.mapSeed,
            playerX: draft.context.playerX, playerY: draft.context.playerY,
            stability: draft.context.stability, outcomeID: draft.context.outcomeID)
        report.route = draft.context.route
        report.campaignReference = draft.context.campaignReference
        report.encounterID = draft.context.encounterID
        report.debugTuningSnapshot = draft.context.debugTuningSnapshot
        report.semanticActionTrail = draft.context.semanticActionTrail
        report.roadmapCheckpoint = DebugRoadmap.current.installedCheckpoint
        do {
            savedPackage = try DebugBugReportOutbox.live.save(report, screenshot: screenshot?.png)
            UIAccessibility.post(notification: .announcement, argument: "Saved on this phone — not yet shared")
        } catch {
            self.error = "Could not save this report: \(error.localizedDescription)"
            UIAccessibility.post(notification: .announcement, argument: "Bug report could not be saved")
        }
    }

    private func exportedFile(in directory: URL) -> URL {
        DebugBugReportOutbox.live.exportURL(for: draft.id, in: directory)
    }
}

private struct DebugBugReportQueueView: View {
    @State private var reports: [(report: DebugBugReport, directory: URL)] = []
    @State private var deletionCandidate: DebugBugReport?
    @State private var submitting: Set<UUID> = []
    @State private var submissionError: String?

    var body: some View {
        List(reports, id: \.report.id) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.report.whatHappened).lineLimit(3)
                Text(entry.report.createdAt.formatted()).font(.caption).foregroundStyle(.secondary)
                Label(transportLabel(entry.report.transportState),
                      systemImage: transportIcon(entry.report.transportState))
                    .font(.caption).foregroundStyle(.secondary)
                ShareLink(item: DebugBugReportOutbox.live.exportURL(for: entry.report, in: entry.directory)) {
                    Label("Share saved report", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
                if let configuration = DebugBugReportRelayConfiguration.live(),
                   entry.report.transportState != .submitted {
                    Button(entry.report.transportState == .needsAttention ? "Retry submission" : "Submit to triage") {
                        submit(entry.report.id, configuration: configuration)
                    }
                    .buttonStyle(.borderless)
                    .disabled(submitting.contains(entry.report.id))
                }
                Button("Delete saved report", role: .destructive) {
                    deletionCandidate = entry.report
                }
                .buttonStyle(.borderless)
            }.padding(.vertical, 4)
        }
        .navigationTitle("Bug queue")
        .overlay { if reports.isEmpty { ContentUnavailableView("No saved reports", systemImage: "ladybug") } }
        .safeAreaInset(edge: .bottom) {
            if let submissionError {
                Text(submissionError).font(.caption).foregroundStyle(.red)
                    .padding(8).background(.regularMaterial, in: Capsule())
            }
        }
        .task {
            _ = DebugBugReportOutbox.live.recoverInterruptedSends()
            reload()
        }
        .alert("Delete this saved report?", isPresented: deletionIsPresented,
               presenting: deletionCandidate) { report in
            Button("Delete", role: .destructive) {
                try? DebugBugReportOutbox.live.remove(report.id)
                deletionCandidate = nil
                reload()
            }
            Button("Cancel", role: .cancel) { deletionCandidate = nil }
        } message: { _ in
            Text("This removes the local report and its screenshot. It cannot be undone.")
        }
    }

    private var deletionIsPresented: Binding<Bool> {
        Binding(get: { deletionCandidate != nil }, set: { if !$0 { deletionCandidate = nil } })
    }

    private func reload() { reports = DebugBugReportOutbox.live.reports() }

    private func submit(_ id: UUID, configuration: DebugBugReportRelayConfiguration) {
        submitting.insert(id)
        submissionError = nil
        Task {
            do {
                _ = try await DebugBugReportSubmissionCoordinator(
                    outbox: .live,
                    transport: DebugBugReportHTTPTransport(
                        endpoint: configuration.endpoint,
                        credential: configuration.credential)
                ).submit(id)
                UIAccessibility.post(notification: .announcement,
                                     argument: "Bug report submitted to triage")
            } catch {
                submissionError = "Submission failed. The report remains saved for retry or sharing."
                UIAccessibility.post(notification: .announcement,
                                     argument: "Submission failed. Report remains saved.")
            }
            submitting.remove(id)
            reload()
        }
    }

    private func transportLabel(_ state: DebugBugReport.TransportState) -> String {
        switch state {
        case .unsent: "Saved locally — not submitted"
        case .sending: "Sending"
        case .submitted: "Submitted"
        case .needsAttention: "Needs retry or manual sharing"
        }
    }

    private func transportIcon(_ state: DebugBugReport.TransportState) -> String {
        switch state {
        case .unsent: "tray"
        case .sending: "arrow.up.circle"
        case .submitted: "checkmark.circle"
        case .needsAttention: "exclamationmark.triangle"
        }
    }
}
#endif
