import SwiftUI

struct SettingsView: View {
    let progressStore: ProgressStore
    @State private var confirmStartOver = false
    @State private var justStartedOver = false

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 460, height: 280)
    }

    @ViewBuilder
    private var generalTab: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start over")
                            .font(.headline)
                        Text("Clears your current lesson progress so you can walk through the tutor again. Historic stats and drill sessions are kept.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button("Start Over…") {
                        confirmStartOver = true
                    }
                }
                .padding(.vertical, 4)

                if justStartedOver {
                    Label("Progress reset. Happy relearning.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                        .transition(.opacity)
                }
            } header: {
                Text("Tutor Progress")
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(
            "Start the tutor over?",
            isPresented: $confirmStartOver,
            titleVisibility: .visible
        ) {
            Button("Start Over", role: .destructive) {
                progressStore.startOver()
                withAnimation { justStartedOver = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { justStartedOver = false }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your lesson checkmarks will clear, but historic stats and saved drill sessions remain.")
        }
    }
}
