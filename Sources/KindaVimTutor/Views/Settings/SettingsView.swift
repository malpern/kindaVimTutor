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
    @State private var bearTokenField: String = KeychainStore.get(.bearAPIToken) ?? ""
    @State private var bearTokenSavedFeedback: Bool = false
    @AppStorage(DrillAppPreferences.preferredNotesKey)
    private var preferredNotesRaw: String = PreferredNotesApp.notes.rawValue

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
            remindersTab
                .tabItem { Label("Reminders", systemImage: "bell") }
            chatAITab
                .tabItem { Label("Chat AI", systemImage: "sparkles") }
            drillAppsTab
                .tabItem { Label("Drill Apps", systemImage: "app.badge") }
        }
        .frame(width: 480, height: 420)
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

    // MARK: - Drill Apps

    @ViewBuilder
    private var drillAppsTab: some View {
        Form {
            Section {
                Text("kindaVim drills can run in real apps so you practice Vim motions the way you'll actually use them. Notes + Mail work out of the box. Bear needs a one-time API token to let the tutor trash drill notes when you finish.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("External Drill Apps")
            }

            Section {
                Picker("Preferred note app", selection: $preferredNotesRaw) {
                    ForEach(PreferredNotesApp.allCases) { app in
                        Text(app.displayName).tag(app.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                Text("Every drill authored for Apple Notes will open in the app you pick here. Mail-based drills are unaffected. Bear opens a fresh note per drill.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } header: {
                Text("Practice App")
            }

            Section {
                SecureField("Bear API token", text: $bearTokenField)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save Token") {
                        KeychainStore.set(bearTokenField, for: .bearAPIToken)
                        withAnimation { bearTokenSavedFeedback = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { bearTokenSavedFeedback = false }
                        }
                    }
                    .disabled(bearTokenField.trimmingCharacters(in: .whitespaces).isEmpty
                              && KeychainStore.get(.bearAPIToken) == nil)

                    if bearTokenSavedFeedback {
                        Label("Saved to Keychain", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                            .transition(.opacity)
                    }
                    Spacer()
                }

                Text("In Bear, open Preferences → Advanced and click “Generate Token.” Without it, drill notes stay in Bear after you finish — you'd need to delete them manually.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } header: {
                Text("Bear")
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
