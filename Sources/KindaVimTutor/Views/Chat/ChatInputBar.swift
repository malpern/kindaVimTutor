import SwiftUI

/// Bottom-of-thread input bar. Return submits; shift-Return (native
/// `TextField(axis: .vertical)` behavior) adds a newline. Send is
/// disabled while a response is streaming so we don't pile prompts.
struct ChatInputBar: View {
    @Bindable var engine: ChatEngine
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField("Ask a Vim question…", text: $engine.input, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($focused)
                .lineLimit(1...5)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                }
                .onSubmit {
                    engine.send()
                    focused = true
                }

            Button(action: { engine.send() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(canSend ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .defaultFocus($focused, true)
        .onAppear {
            // onAppear fires before the view is fully in the hierarchy,
            // so an immediate focus-set is swallowed when a sibling
            // (e.g. the sidebar toggle) holds window focus. A one-tick
            // defer lets the window resolve its responder chain first.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                focused = true
            }
        }
    }

    private var canSend: Bool {
        !engine.isResponding &&
            !engine.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
