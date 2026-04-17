import SwiftUI

/// Dot-pager anchored to the bottom of the canvas. Shows one dot per step in
/// the lesson, with the current step highlighted. Purely presentational.
struct StepIndicatorView: View {
    let stepCount: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.primary : Color.primary.opacity(0.15))
                    .frame(width: index == currentIndex ? 7 : 6, height: index == currentIndex ? 7 : 6)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }
}

#Preview("5 steps, on step 2") {
    StepIndicatorView(stepCount: 5, currentIndex: 2)
        .padding()
}
