import SwiftUI

/// Post-drill coaching panel. Designed around progressive disclosure:
///
/// - **Default**: a single summary line that carries the gamification
///   hit ("★ New best · 5 keystrokes · 1.4s") plus Continue / Retry
///   buttons and a quiet Details toggle.
/// - **Expanded** (one click): the full tier panel — your attempt,
///   personal best, chapter target, and a locked teaser for any
///   future-chapter technique that would shave keystrokes here.
///
/// Session-remembered auto-expand: once the student opens Details on
/// any drill in a session, subsequent drills open pre-expanded. The
/// preference resets on app relaunch so the default stays simple.
struct DrillCoachingView: View {
    let exercise: Exercise
    let lastKeystrokes: Int
    let lastTime: TimeInterval
    let personalBest: ExerciseResult?
    /// Target for the LAST rep's variation, not the exercise as a
    /// whole. Vimified drills have different cursor starts per
    /// variation, so the target varies too.
    let chapterTarget: Int?
    let futureLessonUnlocked: Bool
    let onContinue: () -> Void
    let onRetry: () -> Void
    @Binding var autoExpandDetails: Bool

    @State private var showDetails: Bool = false

    // MARK: - Achievement classification

    private enum Achievement {
        case first
        case newBest
        case beatTarget
        case hitTarget
        case completed
    }

    private var achievement: Achievement {
        let beatPB: Bool = {
            guard let pb = personalBest else { return false }
            if lastKeystrokes < pb.keystrokeCount { return true }
            if lastKeystrokes == pb.keystrokeCount && lastTime < pb.timeSeconds { return true }
            return false
        }()

        if personalBest == nil { return .first }
        if beatPB { return .newBest }
        if let target = chapterTarget {
            if lastKeystrokes < target { return .beatTarget }
            if lastKeystrokes == target { return .hitTarget }
        }
        return .completed
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryLine
                .id("summary-\(lastKeystrokes)-\(lastTime)")
                .transition(.scale(scale: 0.92).combined(with: .opacity))

            if showDetails {
                detailsPanel
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            actionRow
        }
        .padding(18)
        .frame(maxWidth: 560)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.28))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(summaryAccent.opacity(0.35), lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        .onAppear {
            // Honor the session-remembered preference.
            showDetails = autoExpandDetails
        }
        .animation(.easeInOut(duration: 0.22), value: showDetails)
    }

    // MARK: - Subviews

    private var summaryLine: some View {
        HStack(spacing: 10) {
            Image(systemName: summaryIconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(summaryAccent)
            Text(summaryTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            Text("·")
                .foregroundStyle(.tertiary)
            Text("\(lastKeystrokes) keystrokes")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Text("·")
                .foregroundStyle(.tertiary)
            Text(formatTime(lastTime))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var detailsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 2)

            tierRow(
                label: "Your attempt",
                value: "\(lastKeystrokes) keystrokes · \(formatTime(lastTime))",
                highlight: achievement == .newBest || achievement == .beatTarget
            )

            if let pb = personalBest {
                tierRow(
                    label: "Personal best",
                    value: "\(pb.keystrokeCount) keystrokes · \(formatTime(pb.timeSeconds))",
                    highlight: false
                )
            }

            if let target = chapterTarget {
                tierRow(
                    label: "Chapter target",
                    value: "\(target) keystrokes",
                    highlight: achievement == .hitTarget || achievement == .beatTarget
                )
            }

            if let opt = exercise.futureOptimization {
                Divider().padding(.vertical, 2)
                futureOptimizationRow(opt)
            }
        }
    }

    private func tierRow(label: String, value: String, highlight: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(highlight ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(highlight ? .green : .primary.opacity(0.85))
        }
    }

    private func futureOptimizationRow(_ opt: Exercise.FutureOptimization) -> some View {
        HStack(spacing: 8) {
            Image(systemName: futureLessonUnlocked ? "bolt.fill" : "bolt")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(futureLessonUnlocked
                                 ? AnyShapeStyle(Color.orange)
                                 : AnyShapeStyle(HierarchicalShapeStyle.tertiary))
            if futureLessonUnlocked {
                Text("Try \(opt.summary) here — you've unlocked it.")
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
            } else {
                Text("A faster technique — \(opt.summary) — unlocks later.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 2)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                let newState = !showDetails
                showDetails = newState
                // Once the student opens Details on any drill this
                // session, remember that preference for the rest of
                // the session so subsequent drills open expanded.
                if newState { autoExpandDetails = true }
            } label: {
                HStack(spacing: 4) {
                    Text(showDetails ? "Hide details" : "Details")
                        .font(.system(size: 12))
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Presentation helpers

    private var summaryIconName: String {
        switch achievement {
        case .first:      return "checkmark.circle.fill"
        case .newBest:    return "star.fill"
        case .beatTarget: return "bolt.fill"
        case .hitTarget:  return "checkmark.circle.fill"
        case .completed:  return "checkmark.circle.fill"
        }
    }

    private var summaryTitle: String {
        switch achievement {
        case .first:      return "Drill complete"
        case .newBest:    return "New personal best"
        case .beatTarget: return "Beat the chapter target"
        case .hitTarget:  return "On target"
        case .completed:  return "Drill complete"
        }
    }

    private var summaryAccent: Color {
        switch achievement {
        case .newBest, .beatTarget: return .orange
        case .hitTarget:            return .green
        case .first, .completed:    return .accentColor
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 10 {
            return String(format: "%.2fs", seconds)
        }
        return String(format: "%.1fs", seconds)
    }
}
