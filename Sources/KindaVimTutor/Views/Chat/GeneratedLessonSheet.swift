import SwiftUI

/// Presents a practice lesson for the user's question. Prefers an
/// existing curriculum lesson when the matched topic has authored
/// lesson(s) — those come with hand-crafted explanation blocks
/// (including rich visualizations like `GrammarGridView`,
/// `FindVsTillView`, `HomeRowView`, etc.) and verified drill text.
/// Only falls back to on-the-fly `LessonGenerator` when no
/// curriculum lesson exists for the concept.
///
/// The sheet reuses `ExplanationView` + `ExerciseContainerView` so
/// a generated lesson looks visually indistinguishable from an
/// authored one. The curriculum path uses the lesson's own
/// `explanation` blocks; the generated path asks the model to pick
/// a named visualization (optional) and emit explanation blocks
/// from the same `ContentBlock` vocabulary.
struct GeneratedLessonSheet: View {
    let question: String
    let topicID: String?
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState
    /// Invoked from the completion view's "Keep learning" CTA.
    /// The host (ChatView) dismisses this sheet and routes the
    /// student — a specific lesson for curriculum-backed sheets,
    /// the curriculum TOC for generated ones.
    var onContinue: ((ContinueAction) -> Void)? = nil

    enum ContinueAction {
        case openLesson(id: String)
        case openTableOfContents
    }

    @Environment(\.dismiss) private var dismiss

    @State private var state: LoadState = .loading
    /// Counter that bumps when the user clicks Regenerate so the
    /// loading Task can be re-triggered via `.task(id:)`.
    @State private var reloadToken: Int = 0
    /// True once all drill reps for the currently-shown exercise
    /// have been recorded as completed by ProgressStore.
    @State private var isLessonComplete: Bool = false
    /// `lastPracticeDate` at the moment this sheet's drill became
    /// active. Any later value means the student just completed a
    /// drill inside this sheet — a cleaner signal than watching the
    /// per-exercise map, which stays stale when re-runs don't beat
    /// a previous best and would fire immediately for curriculum
    /// exercises the student already completed in a prior session.
    @State private var practiceBaseline: Date?

    enum LoadState {
        case loading
        case curriculum(lesson: Lesson, chapter: Chapter, exercise: Exercise, exerciseNumber: Int)
        case generated(LessonGenerator.GeneratedLesson)
        case failed(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider().opacity(0.3)
            ScrollView {
                if isLessonComplete {
                    completionView
                        .padding(.vertical, 4)
                } else {
                    content
                        .padding(.vertical, 4)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 560)
        .task(id: reloadToken) {
            await loadLesson()
        }
        // Snapshot the global practice date at the moment a drill
        // becomes available so we can tell "a rep just landed in
        // this sheet" apart from "the exercise was already in the
        // completion map." ProgressStore bumps `lastPracticeDate`
        // on every `recordCompletion`, regardless of whether the
        // new result beat the prior best.
        .onChange(of: currentExerciseID) { _, newID in
            if newID != nil {
                practiceBaseline = progressStore.progress.lastPracticeDate
                isLessonComplete = false
            }
        }
        .onChange(of: progressStore.progress.lastPracticeDate) { _, newDate in
            guard let baseline = practiceBaseline else { return }
            guard let newDate, newDate > baseline else { return }
            // ExerciseContainerView's `celebrateCompletion()` guards
            // on `Curriculum.lesson(containing:)` so it skips
            // confetti for generated drills. Fire it here for both
            // paths so the student always gets Raycast confetti.
            Confetti.fireBurst(times: 2, interval: 0.35)
            withAnimation(.easeOut(duration: 0.25)) { isLessonComplete = true }
        }
        .onChange(of: reloadToken) { _, _ in
            isLessonComplete = false
            practiceBaseline = progressStore.progress.lastPracticeDate
        }
    }

    /// The id of the exercise currently being drilled — used to key
    /// the ProgressStore observer.
    private var currentExerciseID: String? {
        switch state {
        case .curriculum(_, _, let exercise, _): return exercise.id
        case .generated(let generated):          return generated.exercise.id
        case .loading, .failed:                  return nil
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                sourceBadge
                Text(question)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            Spacer()
            if canRegenerate {
                Button("Regenerate", systemImage: "arrow.clockwise") {
                    reloadToken &+= 1
                    state = .loading
                }
                .disabled({
                    if case .loading = state { return true }
                    return false
                }())
            }
            Button("Close") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
    }

    /// The curriculum path has verified drills — regenerating would
    /// discard a good authored lesson in favor of an unverified one.
    /// Only expose the button for generated or failed states.
    private var canRegenerate: Bool {
        if case .generated = state { return true }
        if case .failed = state { return true }
        return false
    }

    @ViewBuilder
    private var sourceBadge: some View {
        switch state {
        case .curriculum(let lesson, let chapter, _, _):
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Chapter \(chapter.number).\(lesson.number) — \(lesson.title)")
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            .foregroundStyle(.secondary)
        case .generated:
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text("Generated lesson")
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            .foregroundStyle(.secondary)
        case .loading, .failed:
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text("Practice")
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            loadingView
        case .curriculum(let lesson, _, let exercise, let exerciseNumber):
            VStack(alignment: .leading, spacing: 24) {
                ExplanationView(blocks: lesson.explanation)
                ExerciseContainerView(
                    exercise: exercise,
                    exerciseNumber: exerciseNumber,
                    progressStore: progressStore,
                    inspectorState: inspectorState
                )
            }
        case .generated(let generated):
            VStack(alignment: .leading, spacing: 24) {
                if let visualization = generated.visualizationBlock {
                    ExplanationView(blocks: [visualization])
                }
                if !generated.explanation.isEmpty {
                    ExplanationView(blocks: generated.explanation)
                }
                ExerciseContainerView(
                    exercise: generated.exercise,
                    exerciseNumber: 1,
                    progressStore: progressStore,
                    inspectorState: inspectorState
                )
            }
        case .failed(let message):
            failureView(message: message)
        }
    }

    /// Success state shown when all drill reps are recorded
    /// complete. Replaces the explanation + drill content with a
    /// celebratory summary and a single primary CTA to return to
    /// the chat thread.
    private var completionView: some View {
        VStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.green)
            }
            .padding(.top, 24)

            Text("Lesson complete")
                .font(.system(size: 22, weight: .semibold))

            if let summary = completionSummary {
                Text(summary)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Text("Back to chat")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)

                Button(action: continueLearning) {
                    HStack(spacing: 6) {
                        Text(keepLearningLabel)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                    )
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    /// Label for the secondary CTA. Curriculum path names the next
    /// lesson explicitly; the generated path points at the TOC.
    private var keepLearningLabel: String {
        if case .curriculum(let lesson, let chapter, _, _) = state,
           let next = Self.nextLesson(after: lesson, chapter: chapter) {
            return "Next: \(next.chapter.number).\(next.lesson.number) \(next.lesson.title)"
        }
        return "Browse lessons"
    }

    private func continueLearning() {
        switch state {
        case .curriculum(let lesson, let chapter, _, _):
            if let next = Self.nextLesson(after: lesson, chapter: chapter) {
                onContinue?(.openLesson(id: next.lesson.id))
            } else {
                // End of curriculum — fall back to the TOC so the
                // student can pick something to revisit instead of
                // hitting a dead end.
                onContinue?(.openTableOfContents)
            }
        case .generated:
            onContinue?(.openTableOfContents)
        case .loading, .failed:
            break
        }
        dismiss()
    }

    /// Resolves the lesson that comes after the given one in the
    /// curriculum: next lesson in the same chapter, or lesson 1 of
    /// the next chapter. Returns nil when we're at the end.
    private static func nextLesson(
        after lesson: Lesson, chapter: Chapter
    ) -> (chapter: Chapter, lesson: Lesson)? {
        if let idx = chapter.lessons.firstIndex(where: { $0.id == lesson.id }),
           idx + 1 < chapter.lessons.count {
            return (chapter, chapter.lessons[idx + 1])
        }
        if let chapterIdx = Curriculum.chapters.firstIndex(where: { $0.id == chapter.id }),
           chapterIdx + 1 < Curriculum.chapters.count,
           let firstLesson = Curriculum.chapters[chapterIdx + 1].lessons.first {
            return (Curriculum.chapters[chapterIdx + 1], firstLesson)
        }
        return nil
    }

    /// One-line tally — "3 reps · 42 keystrokes" — pulled from
    /// progressStore's record for the current exercise. Falls back
    /// to a plain "Nice work" when no data is present.
    private var completionSummary: String? {
        guard let id = currentExerciseID,
              let result = progressStore.progress.completedExercises[id]
        else { return "Nice work." }
        let reps = result.attempts
        return "\(reps) reps · \(result.keystrokeCount) keystrokes"
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            Text("Building a lesson for this concept…")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 32)
    }

    private func failureView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Couldn't build a lesson", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try Again") {
                reloadToken &+= 1
                state = .loading
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Load

    private func loadLesson() async {
        // 1. Prefer an authored curriculum lesson when the matched
        //    topic points at one — authored lessons are verified,
        //    come with explanation blocks + visualizations, and
        //    don't cost an API round-trip.
        if let match = resolveCurriculumLesson() {
            state = .curriculum(
                lesson: match.lesson,
                chapter: match.chapter,
                exercise: match.exercise,
                exerciseNumber: match.exerciseNumber
            )
            return
        }

        // 2. Fall back to on-the-fly generation when no curriculum
        //    lesson covers the concept.
        guard let apiKey = AIBackendSettings.openAIKey else {
            state = .failed("Add an OpenAI API key in Settings → Chat AI.")
            return
        }
        let topic: HelpTopic? = topicID.flatMap { id in
            KindaVimHelpCorpus.topics.first(where: { $0.id == id })
        }
        do {
            let lesson = try await LessonGenerator.generate(
                question: question,
                topic: topic,
                apiKey: apiKey
            )
            state = .generated(lesson)
        } catch {
            let description = (error as? LocalizedError)?.errorDescription
                ?? String(describing: error)
            state = .failed(description)
        }
    }

    /// Score each lesson in the matched topic's `lessonIDs` by how
    /// well its `motionsIntroduced` matches the user's question,
    /// then return the best-matching lesson with exercises. Falls
    /// back to the first lesson with exercises when no motion token
    /// overlaps. This matters for multi-lesson topics like
    /// line-motions (ch1.l7, ch1.l8, ch4.l5) — a question about
    /// paragraphs should route to ch4.l5 (`{`,`}`), not ch1.l7
    /// (`0`,`^`,`$`).
    private func resolveCurriculumLesson() -> CurriculumMatch? {
        guard let topicID,
              let topic = KindaVimHelpCorpus.topics.first(where: { $0.id == topicID })
        else { return nil }

        let motionTokens = Self.motionTokens(in: question)
        let wordTokens = Self.wordTokens(in: question)

        var best: CurriculumMatch?
        var bestScore = -1
        // `index` retains authored lesson order so ties break toward
        // the first-listed lesson (usually the foundational one).
        for (index, lessonID) in topic.lessonIDs.enumerated() {
            for chapter in Curriculum.chapters {
                guard let lesson = chapter.lessons.first(where: { $0.id == lessonID }),
                      let exercise = lesson.exercises.first
                else { continue }
                let motions = Set(lesson.motionsIntroduced)
                let motionOverlap = motions.intersection(motionTokens).count
                let lessonPhrase = (lesson.title + " " + lesson.subtitle).lowercased()
                let wordOverlap = wordTokens.reduce(0) { acc, word in
                    acc + (lessonPhrase.contains(word) ? 1 : 0)
                }
                // Motion match weighs heavier than prose-word match.
                // `-index` breaks ties toward earlier lessons.
                let score = motionOverlap * 100 + wordOverlap * 10 - index
                if score > bestScore {
                    bestScore = score
                    let exerciseNumber = (lesson.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0) + 1
                    best = CurriculumMatch(
                        chapter: chapter,
                        lesson: lesson,
                        exercise: exercise,
                        exerciseNumber: exerciseNumber
                    )
                }
            }
        }
        return best
    }

    /// Motion-like tokens in the question — anything inside backticks,
    /// plus bare single-character Vim-motion symbols. Case-preserved
    /// so `G` stays uppercase.
    private static func motionTokens(in text: String) -> Set<String> {
        var out: Set<String> = []
        var cursor = text.startIndex
        while cursor < text.endIndex {
            if text[cursor] == "`" {
                let after = text.index(after: cursor)
                if let close = text[after...].firstIndex(of: "`") {
                    out.insert(String(text[after..<close]))
                    cursor = text.index(after: close)
                    continue
                }
            }
            cursor = text.index(after: cursor)
        }
        let motionSymbols: Set<Character> = ["{", "}", "(", ")", "^", "$", "0"]
        for ch in text where motionSymbols.contains(ch) {
            out.insert(String(ch))
        }
        return out
    }

    /// Content words in the question (lowercased, ≥4 chars, stopwords
    /// stripped). Used to cross-score against lesson title/subtitle
    /// so natural-language questions — "how do I jump between
    /// paragraphs" — can still pick the right lesson when no motion
    /// token is present.
    private static func wordTokens(in text: String) -> Set<String> {
        let stopwords: Set<String> = [
            "about", "after", "again", "also", "another", "around",
            "back", "been", "before", "between", "both",
            "come", "could",
            "does", "doing", "down",
            "each", "every",
            "from",
            "have", "here", "hold", "how",
            "into",
            "just",
            "keep",
            "like", "long",
            "make", "many", "more", "most", "move", "much",
            "only", "over",
            "same", "some", "such",
            "than", "that", "them", "then", "there", "these", "they",
            "this", "those", "through", "time",
            "under", "using",
            "want", "was", "what", "when", "where", "which", "while",
            "will", "with", "would",
            "you", "your",
        ]
        let lower = text.lowercased()
        let parts = lower.split(whereSeparator: { !$0.isLetter })
        var out: Set<String> = []
        for part in parts where part.count >= 4 {
            let word = String(part)
            guard !stopwords.contains(word) else { continue }
            out.insert(word)
        }
        return out
    }

    private struct CurriculumMatch {
        let chapter: Chapter
        let lesson: Lesson
        let exercise: Exercise
        let exerciseNumber: Int
    }
}
