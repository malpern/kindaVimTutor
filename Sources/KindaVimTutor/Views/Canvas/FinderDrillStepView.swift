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
        VStack(spacing: 0) {
            Spacer()
            content
                .frame(maxWidth: 640, alignment: .leading)
            Spacer().frame(minHeight: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 56)
        .animation(.easeInOut(duration: 0.25), value: engine.state)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            label
            Text(spec.title)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.primary)
            Text(spec.subtitle)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider().opacity(0.3)

            switch engine.state {
            case .idle:
                introBody
            case .preparing, .seeding, .active, .repCompleted:
                inProgressBody
            case .drillCompleted:
                completionBody
            }
        }
    }

    private var label: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 12))
                .foregroundStyle(.orange)
            Text("Finder Drill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }

    // MARK: - States

    private var introBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("We'll open a fresh folder in Finder with \(spec.reps.count) navigation challenges. A floating coach will tell you which way to go; the target file is marked in red.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    Task { await startDrill() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Finder Drill")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var inProgressBody: some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .font(.system(size: 22))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse, options: .repeating)
            VStack(alignment: .leading, spacing: 2) {
                Text("Switch to Finder and follow the coach")
                    .font(.system(size: 14, weight: .medium))
                Text("Rep \(min(engine.completedRepIndex + 1, engine.reps.count)) of \(engine.reps.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
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
                    Text("Continue")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)

                Button {
                    Task { await startDrill() }
                } label: {
                    Text("Retry")
                        .font(.system(size: 13))
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
