import SwiftUI

struct ChapterRowView: View {
    let chapter: Chapter

    var body: some View {
        Label {
            Text(chapter.title)
                .font(.headline)
                .fontWeight(.semibold)
        } icon: {
            Image(systemName: chapter.systemImage)
                .foregroundStyle(.tint)
        }
    }
}
