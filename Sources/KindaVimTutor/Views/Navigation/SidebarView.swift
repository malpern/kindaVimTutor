import SwiftUI

struct SidebarView: View {
    let chapters: [Chapter]
    @Binding var selectedLessonId: String?
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState

    @State private var expandedChapterId: String?

    // Which chapter contains the selected lesson?
    private var selectedChapterId: String? {
        guard let selectedLessonId else { return nil }
        return chapters.first { ch in
            ch.lessons.contains { $0.id == selectedLessonId }
        }?.id
    }

    var body: some View {
        List(selection: $selectedLessonId) {
            if inspectorState.isVisible {
                Section {
                    DrillSidebarSection(state: inspectorState)
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 14, trailing: 8))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }

            ForEach(chapters) { chapter in
                let isExpanded = expandedChapterId == chapter.id

                // Chapter header — tall, tracked, uppercase caption.
                Section {
                    if isExpanded {
                        ForEach(chapter.lessons) { lesson in
                            LessonRowView(
                                lesson: lesson,
                                chapterNumber: chapter.number,
                                isCompleted: progressStore.isLessonCompleted(lesson)
                            )
                            .tag(lesson.id)
                        }
                    }
                } header: {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedChapterId = (expandedChapterId == chapter.id) ? nil : chapter.id
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: chapter.systemImage)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                                .frame(width: 14)
                            Text(chapter.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.6)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.quaternary)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        }
                        .contentShape(Rectangle())
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .navigationTitle("kindaVim Tutor")
        .onAppear {
            // Auto-expand the chapter of the selected lesson
            expandedChapterId = selectedChapterId
        }
        .onChange(of: selectedLessonId) {
            // Auto-expand when selection changes
            if let chId = selectedChapterId, expandedChapterId != chId {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedChapterId = chId
                }
            }
        }
    }
}
