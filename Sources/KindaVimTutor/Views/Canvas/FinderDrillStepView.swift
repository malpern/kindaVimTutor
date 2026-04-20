import SwiftUI

/// Full-canvas step view for a Finder-navigation drill. Acts as the
/// launcher: explains the exercise, offers a Start button, then
/// (while the drill runs in Finder + floating panel) shows a quiet
/// in-progress placeholder. On completion it flips to a summary
/// with a Continue button to advance to the next step.
struct FinderDrillStepView: View {
    let spec: FinderDrillSpec
    let modeMonitor: ModeMonitor
    var onAdvance: (() -> Void)?

    @State private var engine = FinderDrillEngine()
    @State private var hasStarted = false

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
    }

    @ViewBuilder
    private var content: some View {
        switch engine.state {
        case .idle:
            introBody
        case .preparing, .seeding, .active, .repCompleted:
            inProgressBody
        case .drillCompleted:
            completionBody
        }
    }

    // MARK: - States

    private var introBody: some View {
        VStack(alignment: .leading, spacing: 28) {
            finderHero

            VStack(alignment: .leading, spacing: 14) {
                label
                Text("Now let's try it in the wild")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Now that you've practiced, let's use the **h**, **j**, **k**, **l** keys to navigate files in a Finder window.")
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
                        Text("Start Finder Drill")
                            .font(.system(size: 14, weight: .medium))
                        KeyCapView(label: "⏎", size: .small)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)

                Text("\(spec.reps.count) challenges · real Finder window · floating coach")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
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

    /// Renders the real macOS Finder icon at hero size. Uses
    /// NSWorkspace so we get Apple's actual multi-resolution asset
    /// instead of a flat SF Symbol — makes the exercise feel like it
    /// lives in the system, not inside the tutor.
    private var finderHero: some View {
        let finderIcon = NSWorkspace.shared.icon(
            forFile: "/System/Library/CoreServices/Finder.app"
        )
        return Image(nsImage: finderIcon)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: 128, height: 128)
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
            .shadow(color: .accentColor.opacity(0.25), radius: 30, y: 0)
    }

    private var inProgressBody: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(alignment: .top, spacing: 28) {
                finderHeroInProgress
                VStack(alignment: .leading, spacing: 14) {
                    inProgressLabel
                    Text("Drill in progress")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Switch to the Finder window — your coaching panel is floating next to it.")
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
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text(engine.currentRepInstruction)
                            .font(.system(size: 16, weight: .medium))
                            .id("inProgressInstruction-\(engine.completedRepIndex)-\(rep.target)")
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
                    Text(engine.completedRepIndex >= engine.reps.count
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
            Text("Switch to Finder")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }

    /// Smaller hero Finder icon for the in-progress state, with a
    /// pulsing accent glow to subtly suggest "your focus should be
    /// over there, not here".
    private var finderHeroInProgress: some View {
        let finderIcon = NSWorkspace.shared.icon(
            forFile: "/System/Library/CoreServices/Finder.app"
        )
        return ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 124, height: 124)
                .blur(radius: 16)
            Image(nsImage: finderIcon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                .symbolEffect(.pulse, options: .repeating)
        }
        .frame(width: 124, height: 124)
    }

    /// Three dot/capsule track showing completed, current, remaining
    /// reps. Redundant with the floating panel's counter, but reads
    /// well at this size and reinforces "this is an N-part thing".
    private var repProgressTrack: some View {
        HStack(spacing: 10) {
            ForEach(0..<engine.reps.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(fillForRep(i))
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(strokeForRep(i), lineWidth: 1)
                    )
            }
            Text("\(min(engine.completedRepIndex + 1, engine.reps.count)) / \(engine.reps.count)")
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

    private var completionBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.green)
                Text("Drill complete")
                    .font(.system(size: 16, weight: .semibold))
            }
            let moves = engine.totalMoves
            let time = engine.totalTime
            HStack(spacing: 24) {
                metric(label: "Reps", value: "\(engine.results.count) / \(spec.reps.count)")
                metric(label: "Keys", value: "\(moves)")
                metric(label: "Time", value: String(format: "%.1fs", time))
            }
            HStack(spacing: 10) {
                Button {
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

                Button {
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
        }
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
        hasStarted = true
        let reps = spec.reps.map { FinderDrillEngine.Rep(start: $0.start, target: $0.target) }
        engine.onDrillCompleted = {
            FinderDrillPanel.shared.finish(engine: engine)
        }
        let ok = await engine.start(
            reps: reps,
            title: spec.title,
            subtitle: spec.subtitle
        )
        if ok {
            FinderDrillPanel.shared.show(engine: engine, modeMonitor: modeMonitor)
        }
    }
}
