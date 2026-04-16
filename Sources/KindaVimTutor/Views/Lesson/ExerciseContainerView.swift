import SwiftUI

struct ExerciseContainerView: View {
    let exercise: Exercise
    let exerciseNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                Label("Exercise \(exerciseNumber)", systemImage: "pencil.and.outline")
                    .font(.headline)
                Spacer()
                difficultyBadge
            }

            // Instruction
            Text(exercise.instruction)
                .font(Typography.body)
                .foregroundStyle(.primary)

            // Editor placeholder — will be replaced with NSTextView in Phase 2
            VStack(alignment: .leading, spacing: 0) {
                Text(exercise.initialText)
                    .font(Typography.code)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppColors.codeBackground)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(AppColors.exerciseBorder.opacity(0.3), lineWidth: 2)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppColors.exerciseBorder)
                    .frame(width: 3)
                    .padding(.vertical, 1)
            }

            // Hints
            if !exercise.hints.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(exercise.hints, id: \.self) { hint in
                            Text(hint)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                } label: {
                    Text("Hint")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .primary.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var difficultyBadge: some View {
        Text(exercise.difficulty.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(difficultyColor.opacity(0.15))
            }
            .foregroundStyle(difficultyColor)
    }

    private var difficultyColor: Color {
        switch exercise.difficulty {
        case .learn: .green
        case .practice: .blue
        case .master: .orange
        }
    }
}
