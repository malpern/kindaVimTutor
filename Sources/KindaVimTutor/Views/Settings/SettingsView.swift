import SwiftUI

struct SettingsView: View {
    let progressStore: ProgressStore
    @State private var confirmStartOver = false
    @State private var justStartedOver = false

    // Reminder prefs — bound to UserDefaults so Start Over doesn't
    // reset them. @AppStorage gives us change tracking for free.
    @AppStorage("notifications.dailyReminderEnabled") private var dailyReminderEnabled: Bool = true
    @AppStorage("notifications.reminderMinutesFromMidnight") private var reminderMinutes: Int = 19 * 60 + 30

    // Chat backend prefs.
    @AppStorage(AIBackendSettings.backendKey) private var backendRaw: String = AIBackend.apple.rawValue
    @State private var openAIKeyField: String = KeychainStore.get(.openAIAPIKey) ?? ""
    @State private var keySavedFeedback: Bool = false

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
            remindersTab
                .tabItem { Label("Reminders", systemImage: "bell") }
            chatAITab
                .tabItem { Label("Chat AI", systemImage: "sparkles") }
        }
        .frame(width: 480, height: 380)
    }

    // MARK: - General

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

    // MARK: - Reminders

    @ViewBuilder
    private var remindersTab: some View {
        Form {
            Section {
                Toggle("Daily practice reminder", isOn: $dailyReminderEnabled)
                    .onChange(of: dailyReminderEnabled) { _, _ in
                        reschedule()
                    }

                if dailyReminderEnabled {
                    HStack {
                        Text("Remind me at")
                        Spacer()
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { dateFromMinutes(reminderMinutes) },
                                set: { newValue in
                                    reminderMinutes = minutesFromDate(newValue)
                                    reschedule()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }

                Text("When you haven't practiced, you'll get a nudge — daily at first, dropping to weekly after three days away, then monthly after three weeks. We'll stop after 90 days of quiet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } header: {
                Text("Practice Reminders")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Chat AI

    @ViewBuilder
    private var chatAITab: some View {
        Form {
            Section {
                Picker("Backend", selection: $backendRaw) {
                    ForEach(AIBackend.allCases) { backend in
                        Text(backend.displayName).tag(backend.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                Text("Chooses which model answers questions that aren't in the curated reference. Canonical answers from the built-in corpus serve instantly either way.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } header: {
                Text("Model")
            }

            if backendRaw == AIBackend.openAI.rawValue {
                Section {
                    SecureField("sk-…", text: $openAIKeyField)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Save Key") {
                            KeychainStore.set(openAIKeyField, for: .openAIAPIKey)
                            withAnimation { keySavedFeedback = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { keySavedFeedback = false }
                            }
                        }
                        .disabled(openAIKeyField.trimmingCharacters(in: .whitespaces).isEmpty
                                  && KeychainStore.get(.openAIAPIKey) == nil)

                        if keySavedFeedback {
                            Label("Saved to Keychain", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.callout)
                                .transition(.opacity)
                        }
                        Spacer()
                    }

                    Text("Stored in the macOS Keychain. If left empty, the app reads `OPENAI_API_KEY` from the launch environment (useful during development).")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                } header: {
                    Text("OpenAI API Key")
                }
            }
        }
        .formStyle(.grouped)
    }

    private func dateFromMinutes(_ minutes: Int) -> Date {
        var comps = DateComponents()
        comps.hour = minutes / 60
        comps.minute = minutes % 60
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func minutesFromDate(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 19) * 60 + (c.minute ?? 30)
    }

    private func reschedule() {
        Task {
            await NotificationService.shared.rescheduleIfNeeded(
                progress: progressStore.progress,
                prefs: NotificationPreferencesStorage.current()
            )
        }
    }
}
