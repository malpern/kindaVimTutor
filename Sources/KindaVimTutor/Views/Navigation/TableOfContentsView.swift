import SwiftUI

/// Curriculum table of contents — every chapter, every lesson, with
/// completion checkmarks pulled from `ProgressStore`. Shown as a
/// sheet after a generated lesson wraps up so the student has a
/// concrete next step: "pick a foundational skill to drill next."
///
/// Not used inside the main navigation stack (that role belongs to
/// `SidebarView`). This view is a one-shot picker.
struct TableOfContentsView: View {
    let chapters: [Chapter]
    let progressStore: ProgressStore
    let onOpenLesson: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider().opacity(0.3)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(chapters) { chapter in
                        chapterSection(chapter)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 520)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Table of contents")
                        .font(.system(size: 11, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                }
                .foregroundStyle(.secondary)
                Text("Pick a lesson to keep going")
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
            }
            Spacer()
            Button("Close") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
    }

    private func chapterSection(_ chapter: Chapter) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: chapter.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Chapter \(chapter.number) — \(chapter.title)")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(completedCount(in: chapter))/\(chapter.lessons.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(chapter.lessons) { lesson in
                    lessonRow(chapter: chapter, lesson: lesson)
                }
            }
        }
    }

    private func lessonRow(chapter: Chapter, lesson: Lesson) -> some View {
        Button {
            onOpenLesson(lesson.id)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: progressStore.isLessonCompleted(lesson)
                    ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(progressStore.isLessonCompleted(lesson)
                        ? AnyShapeStyle(Color.green)
                        : AnyShapeStyle(HierarchicalShapeStyle.tertiary))
                Text("\(chapter.number).\(lesson.number) \(lesson.title)")
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                if !lesson.subtitle.isEmpty {
                    Text("— \(lesson.subtitle)")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func completedCount(in chapter: Chapter) -> Int {
        chapter.lessons.filter { progressStore.isLessonCompleted($0) }.count
    }
}
