import AppKit
import SwiftUI

/// Full-canvas step view for an "in the wild" text-editing drill
/// (Notes / Mail). Mirrors FinderDrillStepView's structure — intro
/// → in-progress → completion — so the two feel like siblings to
/// the student.
struct ExternalTextDrillStepView: View {
    let spec: ExternalTextDrillSpec
    let modeMonitor: ModeMonitor
    var onAdvance: (() -> Void)?

    private let autoAdvanceDuration: Double = 2.5

    @State private var engine: ExternalTextDrillEngine
    @State private var startError: String?
    @State private var autoAdvanceRemaining: Double?
    @State private var autoAdvanceTask: Task<Void, Never>?

    init(spec: ExternalTextDrillSpec,
         modeMonitor: ModeMonitor,
         onAdvance: (() -> Void)? = nil) {
        self.spec = spec
        self.modeMonitor = modeMonitor
        self.onAdvance = onAdvance
        _engine = State(initialValue: ExternalTextDrillEngine(
            surface: Self.makeSurface(for: spec.preferredApp),
            spec: spec
        ))
    }

    /// Build the surface adapter for the authored preferred app.
    /// Mail isn't implemented yet — fall back to Notes when the
    /// student picks a Mail drill, so the UI can at least run.
    private static func makeSurface(for app: ExternalTextDrillSpec.App) -> ExternalTextSurface {
        switch app {
        case .notes: return NotesSurface()
        case .mail:  return MailSurface()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(minHeight: 60)
            content
                .frame(maxWidth: 640, alignment: .leading)
            Spacer().frame(minHeight: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 56)
        .animation(.easeInOut(duration: 0.25), value: engine.state)
        .onDisappear {
            switch engine.state {
            case .preparing, .active, .repCompleted:
                ExternalTextDrillPanel.shared.abort(engine: engine)
            case .idle, .drillCompleted:
                break
            }
            autoAdvanceTask?.cancel()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch engine.state {
        case .idle:
            introBody
        case .preparing, .active, .repCompleted:
            inProgressBody
        case .drillCompleted:
            completionBody
        }
    }

    // MARK: - Intro

    private var introBody: some View {
        VStack(alignment: .leading, spacing: 28) {
            surfaceHero

            VStack(alignment: .leading, spacing: 14) {
                label
                Text("Now let's try it in the wild")
                    .font(.system(size: 32, weight: .semibold))
                Text(markdown: spec.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }

            HStack(spacing: 10) {
                Button {
                    Task { await startDrill() }
                } label: {
                    HStack(spacing: 10) {
                        Text("Start \(surfaceDisplayName) Drill")
                            .font(.system(size: 14, weight: .medium))
                        KeyCapView(label: "⏎", size: .small)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)

                Text("\(spec.reps.count) challenges · real \(surfaceDisplayName) · floating coach")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            if let startError {
                Text(startError)
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var label: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
            Text("Time to Practice in the Wild")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }

    private var surfaceHero: some View {
        let icon = NSWorkspace.shared.icon(
            forFile: surfaceAppPath
        )
        return Image(nsImage: icon)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: 128, height: 128)
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
            .shadow(color: .accentColor.opacity(0.25), radius: 30, y: 0)
    }

    private var surfaceDisplayName: String {
        switch spec.preferredApp {
        case .notes: "Notes"
        case .mail:  "Mail"
        }
    }

    private var surfaceAppPath: String {
        switch spec.preferredApp {
        case .notes: "/System/Applications/Notes.app"
        case .mail:  "/System/Applications/Mail.app"
        }
    }

    // MARK: - In progress

    private var inProgressBody: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(alignment: .top, spacing: 28) {
                surfaceHeroInProgress
                VStack(alignment: .leading, spacing: 14) {
                    inProgressLabel
                    Text("Drill in progress")
                        .font(.system(size: 30, weight: .semibold))
                    Text("Switch to \(surfaceDisplayName) — your coaching panel is floating next to it.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                Spacer(minLength: 0)
            }

            Divider().opacity(0.25)

            repProgressTrack

            if let rep = engine.currentRep, engine.state != .repCompleted {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current challenge")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .tracking(0.7)
                    HStack(spacing: 8) {
                        Circle().fill(Color.accentColor).frame(width: 8, height: 8)
                        Text(markdown: rep.instruction)
                            .font(.system(size: 16, weight: .medium))
                            .id("inProgressInstruction-\(engine.completedRepIndex)")
                            .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.22), value: engine.completedRepIndex)
            }

            if engine.state == .repCompleted {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: engine.completedRepIndex)
                    Text(engine.completedRepIndex >= engine.spec.reps.count
                         ? "Drill complete"
                         : "Nice — next rep loading…")
                        .font(.system(size: 15, weight: .medium))
                }
                .transition(.opacity)
            }
        }
    }

    private var inProgressLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
            Text("Switch to \(surfaceDisplayName)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }

    private var surfaceHeroInProgress: some View {
        let icon = NSWorkspace.shared.icon(forFile: surfaceAppPath)
        return ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 124, height: 124)
                .blur(radius: 16)
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                .symbolEffect(.pulse, options: .repeating)
        }
        .frame(width: 124, height: 124)
    }

    private var repProgressTrack: some View {
        HStack(spacing: 10) {
            ForEach(0..<engine.spec.reps.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(fillForRep(i))
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(strokeForRep(i), lineWidth: 1)
                    )
            }
            Text("\(min(engine.completedRepIndex + 1, engine.spec.reps.count)) / \(engine.spec.reps.count)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 36, alignment: .trailing)
        }
        .animation(.easeInOut(duration: 0.25), value: engine.completedRepIndex)
    }

    private func fillForRep(_ i: Int) -> Color {
        if i < engine.completedRepIndex { return Color.accentColor }
        if i == engine.completedRepIndex { return Color.accentColor.opacity(0.35) }
        return Color.white.opacity(0.05)
    }

    private func strokeForRep(_ i: Int) -> Color {
        if i <= engine.completedRepIndex { return Color.accentColor.opacity(0.5) }
        return Color.white.opacity(0.12)
    }

    // MARK: - Completion

    private var completionBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.green)
                Text("Drill complete")
                    .font(.system(size: 16, weight: .semibold))
            }
            HStack(spacing: 24) {
                metric(label: "Reps", value: "\(engine.results.count) / \(spec.reps.count)")
                metric(label: "Keys", value: "\(engine.totalKeystrokes)")
                metric(label: "Time", value: String(format: "%.1fs", totalTime))
            }
            HStack(spacing: 10) {
                continueButton
                retryButton
                autoAdvanceLabel
            }
            autoAdvanceProgressBar
        }
        .onAppear { startAutoAdvance() }
    }

    private var totalTime: Double {
        engine.results.reduce(0) { $0 + $1.timeSeconds }
    }

    private var continueButton: some View {
        Button {
            cancelAutoAdvance()
            onAdvance?()
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.system(size: 14, weight: .medium))
                KeyCapView(label: "⏎", size: .small)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
    }

    private var retryButton: some View {
        Button {
            cancelAutoAdvance()
            Task { await startDrill() }
        } label: {
            HStack(spacing: 6) {
                Text("Retry")
                    .font(.system(size: 13))
                KeyCapView(label: "R", size: .small)
            }
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("r", modifiers: [])
    }

    @ViewBuilder
    private var autoAdvanceLabel: some View {
        if let remaining = autoAdvanceRemaining {
            Text("Continuing in \(String(format: "%.1f", remaining))s…")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var autoAdvanceProgressBar: some View {
        if let remaining = autoAdvanceRemaining {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(Color.accentColor.opacity(0.6))
                        .frame(
                            width: geo.size.width * (remaining / autoAdvanceDuration)
                        )
                }
            }
            .frame(height: 3)
            .frame(maxWidth: 260)
            .animation(.linear(duration: 0.05), value: remaining)
        }
    }

    private func startAutoAdvance() {
        cancelAutoAdvance()
        autoAdvanceRemaining = autoAdvanceDuration
        autoAdvanceTask = Task { @MainActor in
            let step = 0.05
            var remaining = autoAdvanceDuration
            while remaining > 0 {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled { return }
                remaining -= step
                autoAdvanceRemaining = max(0, remaining)
            }
            autoAdvanceRemaining = nil
            onAdvance?()
        }
    }

    private func cancelAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        autoAdvanceRemaining = nil
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
    }

    // MARK: - Engine wiring

    private func startDrill() async {
        startError = nil
        engine.onDrillCompleted = {
            ExternalTextDrillPanel.shared.finish(engine: engine)
        }
        do {
            try await engine.start()
            ExternalTextDrillPanel.shared.show(
                engine: engine, modeMonitor: modeMonitor
            )
        } catch ExternalTextDrillEngine.StartError.usabilityFailed(let reason) {
            startError = reason
        } catch {
            startError = "Couldn't start drill. \(error.localizedDescription)"
        }
    }
}

private extension Text {
    init(markdown: String) {
        if let attr = try? AttributedString(markdown: markdown) {
            self.init(attr)
        } else {
            self.init(markdown)
        }
    }
}
