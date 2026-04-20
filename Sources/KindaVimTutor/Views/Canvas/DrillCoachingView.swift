import SwiftUI

/// Post-drill coaching panel. Shows the full picture at once:
/// achievement headline, a stacked comparison of your attempt vs
/// personal best vs chapter target, any future-lesson teaser, and the
/// Continue / Retry actions — all with visible keyboard affordances.
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

    private enum Achievement {
        case first, newBest, beatTarget, hitTarget, completed
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headline
                .id("summary-\(lastKeystrokes)-\(lastTime)")
                .transition(.scale(scale: 0.92).combined(with: .opacity))

            comparisonPanel

            if let opt = exercise.futureOptimization {
                Divider().opacity(0.4)
                futureOptimizationRow(opt)
            }

            actionRow
        }
        .padding(20)
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
    }

    // MARK: - Headline

    private var headline: some View {
        HStack(spacing: 12) {
            Image(systemName: summaryIconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(summaryAccent)
            Text(summaryTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    // MARK: - Comparison

    private var comparisonPanel: some View {
        VStack(spacing: 6) {
            tierRow(
                label: "Your attempt",
                keystrokes: lastKeystrokes,
                time: lastTime,
                highlight: achievement == .newBest || achievement == .beatTarget,
                isPrimary: true
            )
            if let pb = personalBest {
                tierRow(
                    label: "Personal best",
                    keystrokes: pb.keystrokeCount,
                    time: pb.timeSeconds,
                    highlight: false,
                    isPrimary: false
                )
            }
            if let target = chapterTarget {
                tierRow(
                    label: "Chapter target",
                    keystrokes: target,
                    time: nil,
                    highlight: achievement == .hitTarget || achievement == .beatTarget,
                    isPrimary: false
                )
            }
        }
    }

    private func tierRow(label: String, keystrokes: Int, time: TimeInterval?,
                         highlight: Bool, isPrimary: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(isPrimary ? .primary : .secondary)
            Spacer()
            HStack(spacing: 10) {
                Text("\(keystrokes) keystrokes")
                    .font(.system(size: isPrimary ? 15 : 13,
                                  weight: isPrimary ? .semibold : .regular,
                                  design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(highlight ? AnyShapeStyle(Color.green)
                                               : AnyShapeStyle(HierarchicalShapeStyle.primary))
                if let time {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(formatTime(time))
                        .font(.system(size: isPrimary ? 15 : 13,
                                      weight: isPrimary ? .semibold : .regular,
                                      design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 3)
    }

    // MARK: - Future optimization teaser

    private func futureOptimizationRow(_ opt: Exercise.FutureOptimization) -> some View {
        HStack(spacing: 8) {
            Image(systemName: futureLessonUnlocked ? "bolt.fill" : "bolt")
                .font(.system(size: 13, weight: .semibold))
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
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: onContinue) {
                HStack(spacing: 6) {
                    Text("Continue")
                        .font(.system(size: 13, weight: .medium))
                    KeyCapView(label: "⏎", size: .small)
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            Button(action: onRetry) {
                HStack(spacing: 6) {
                    Text("Retry")
                        .font(.system(size: 13))
                    KeyCapView(label: "R", size: .small)
                }
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("r", modifiers: [])

            Spacer()
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
        if seconds < 10 { return String(format: "%.2fs", seconds) }
        return String(format: "%.1fs", seconds)
    }
}
