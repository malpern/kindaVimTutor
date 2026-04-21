import AppKit
import SwiftUI

/// Floating coaching panel for the external-text drill (Notes /
/// Mail). Sibling to FinderDrillCoachingView — same visual vocabulary
/// (black card, orange identity tint, accent pops, success flash)
/// so the student sees a coherent family of drills.
struct ExternalTextDrillCoachingView: View {
    let engine: ExternalTextDrillEngine
    let modeMonitor: ModeMonitor

    /// Counts keypresses landing in the target app while the student
    /// is stuck in insert mode — after two, the esc prompt escalates
    /// from calm secondary text to an orange warning.
    @State private var insertModeActivity: Int = 0
    @State private var keydownMonitor: Any?

    private var showsInsertModePrompt: Bool {
        engine.state == .active && modeMonitor.currentMode == .insert
    }

    private var isInsertModeEscalated: Bool { insertModeActivity >= 2 }

    var body: some View {
        card
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(width: 300)
            .background(panelBackground)
            .overlay(panelBorder)
            .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
            .fixedSize(horizontal: false, vertical: true)
            .animation(.easeInOut(duration: 0.18), value: showsInsertModePrompt)
            .onChange(of: modeMonitor.currentMode) { _, newValue in
                if newValue != .insert { insertModeActivity = 0 }
            }
            .onChange(of: engine.completedRepIndex) { _, _ in
                if engine.state == .active { insertModeActivity = 0 }
            }
            .onAppear { installKeydownWatcher() }
            .onDisappear { removeKeydownWatcher() }
    }

    @ViewBuilder
    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleRow
            if engine.state == .repCompleted {
                successFlash.transition(.opacity)
            } else if showsInsertModePrompt {
                insertModeGuidance.transition(.opacity)
            } else {
                directionGuidance.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: engine.state)
    }

    // MARK: - Title row

    private var titleRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: surfaceIconName)
                .font(.system(size: 16))
                .foregroundStyle(Color.orange)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.orange.opacity(0.15)))
            VStack(alignment: .leading, spacing: 1) {
                Text(engine.spec.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Exercise \(min(engine.completedRepIndex + 1, engine.spec.reps.count)) / \(engine.spec.reps.count)")
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.7)
            }
            Spacer()
        }
    }

    private var surfaceIconName: String {
        switch engine.spec.preferredApp {
        case .notes: "note.text"
        case .mail:  "envelope.fill"
        }
    }

    // MARK: - Direction guidance

    private var directionGuidance: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                Text(markdown: engine.currentRep?.instruction ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .id("repInstruction-\(engine.completedRepIndex)")
        }
        .animation(.easeOut(duration: 0.22), value: engine.completedRepIndex)
    }

    // MARK: - Success flash

    private var successFlash: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
                .symbolEffect(.bounce, value: engine.completedRepIndex)
            VStack(alignment: .leading, spacing: 2) {
                Text("Got it!")
                    .font(.system(size: 15, weight: .semibold))
                Text(engine.completedRepIndex >= engine.spec.reps.count
                     ? "Drill complete"
                     : "Next one coming…")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .id("success-\(engine.completedRepIndex)")
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }

    // MARK: - Insert mode guidance

    private var insertModeGuidance: some View {
        let tint: Color = isInsertModeEscalated ? .orange : .secondary
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Press")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                KeyCapView(label: "esc", size: .small)
                Text("to switch to NORMAL mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
            }
            Text(isInsertModeEscalated
                 ? "You're still in insert mode"
                 : "You're in insert mode")
                .font(.system(size: 11))
                .foregroundStyle(tint)
        }
        .animation(.easeInOut(duration: 0.22), value: isInsertModeEscalated)
    }

    // MARK: - Chrome

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.black.opacity(0.88))
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(.white.opacity(0.1), lineWidth: 0.75)
    }

    // MARK: - Keydown watcher

    private func installKeydownWatcher() {
        guard keydownMonitor == nil else { return }
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags
            if flags.contains(.command) || flags.contains(.option) { return }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard engine.state == .active,
                          modeMonitor.currentMode == .insert
                    else { return }
                    insertModeActivity += 1
                }
            }
        }
        keydownMonitor = monitor
    }

    private func removeKeydownWatcher() {
        if let keydownMonitor {
            NSEvent.removeMonitor(keydownMonitor)
        }
        keydownMonitor = nil
    }
}

private extension Text {
    /// Minimal markdown helper — falls back to plain text if the
    /// string isn't valid markdown (e.g. empty).
    init(markdown: String) {
        if let attr = try? AttributedString(markdown: markdown) {
            self.init(attr)
        } else {
            self.init(markdown)
        }
    }
}
