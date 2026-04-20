import SwiftUI

struct TitleStepView: View {
    let lesson: Lesson
    let chapterTitle: String
    var onAdvance: (() -> Void)? = nil

    @State private var showChapter = false
    @State private var showSubtitle = false
    @State private var showHint = false
    @State private var skipTypewriter = false
    @State private var hintTask: Task<Void, Never>?

    private var animationID: String { "title.\(lesson.id)" }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Chapter label — fades in first, no movement
            Text(chapterHeader)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
                .tracking(2)
                .opacity(showChapter ? 1 : 0)
                .offset(y: showChapter ? 0 : 4)

            // Title. Typewrites on first visit, otherwise shows final
            // text immediately — back-nav to a lesson you've already
            // seen shouldn't make you wait through an animation again.
            Group {
                if skipTypewriter {
                    Text(lesson.title)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                } else {
                    TypewriterText(
                        lesson.title,
                        font: .system(size: 44, weight: .bold),
                        foregroundStyle: .primary,
                        alignment: .center
                    ) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showSubtitle = true
                        }
                    }
                }
            }
            .tracking(-1.2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 600)

            // Subtitle — static Text with a quick fade-in. Previously a
            // second typewriter which felt slow on every visit.
            if showSubtitle {
                Text(lesson.subtitle)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .tracking(-0.3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 640)
                    .transition(.opacity)
            }

            Spacer()

            if showHint {
                AdvanceHintView("to begin", action: onAdvance)
                    .padding(.bottom, 44)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            let tracker = AnimationReplayTracker.shared
            if tracker.hasPlayed(animationID) {
                // Instant-appear path for return visits.
                skipTypewriter = true
                showChapter = true
                showSubtitle = true
                showHint = true
            } else {
                tracker.markPlayed(animationID)
                withAnimation(.spring(duration: 0.45, bounce: 0.0).delay(0.05)) {
                    showChapter = true
                }
                // Typewriter's completion callback triggers showSubtitle.
                // Hint follows shortly after subtitle appears. Store
                // the task so .onDisappear can cancel it — otherwise
                // the sleep keeps running and writes to @State after
                // the view is gone.
                hintTask?.cancel()
                hintTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        showHint = true
                    }
                }
            }
        }
        .onDisappear {
            hintTask?.cancel()
            hintTask = nil
            showChapter = false
            showSubtitle = false
            showHint = false
            skipTypewriter = false
        }
    }

    private var chapterHeader: String {
        let base = chapterTitle.uppercased()
        guard let num = chapterNumber(from: lesson.id) else { return base }
        return "CHAPTER \(num) · \(base)"
    }

    /// Extract the chapter number from a lesson id like "ch1.l0" or
    /// "ch10.l2". Returns nil if the id doesn't follow that convention.
    private func chapterNumber(from lessonId: String) -> Int? {
        guard lessonId.hasPrefix("ch") else { return nil }
        let afterCh = lessonId.dropFirst(2)
        guard let dot = afterCh.firstIndex(of: ".") else { return nil }
        return Int(afterCh[..<dot])
    }
}
