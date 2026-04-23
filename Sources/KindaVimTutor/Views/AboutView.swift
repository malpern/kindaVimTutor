import SwiftUI
import AppKit

/// About window showing the app icon, version, and credits. Modeled
/// on the companion Be Kind, Rewind project's About screen so
/// Malpern's macOS apps share a consistent "about" look.
struct AboutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            artwork
            details
            footer
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 36)
        .frame(width: 620, height: 730)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(AboutWindowConfigurator(size: NSSize(width: 620, height: 730)))
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = Bundle.module.url(forResource: "app-icon-about", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            VStack(spacing: 0) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 360, height: 360)
                    .scaleEffect(1.12)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.10), radius: 18, y: 8)
        }
    }

    private var details: some View {
        VStack(spacing: 16) {
            Text("kindaVim Tutor")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Label("Version \(marketingVersion)", systemImage: "graduationcap.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.quinary, in: Capsule())

            Text("Learn Vim motions by practicing them. Drills drive the kindaVim engine underneath, so what you learn works everywhere on macOS.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 420)

            HStack(spacing: 10) {
                aboutPoint("Six chapters", systemImage: "book.closed")
                aboutPoint("Drill-first learning", systemImage: "keyboard")
                aboutPoint("Real Vim muscle memory", systemImage: "bolt.fill")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("By Micah Alpern")
                        .font(.subheadline.weight(.semibold))
                    Link(destination: URL(string: "https://twitter.com/malpern")!) {
                        Text("@malpern on Twitter")
                            .font(.caption)
                    }
                    .buttonStyle(.link)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Link(destination: URL(string: "https://kindavim.app")!) {
                        Label("kindavim.app", systemImage: "arrow.up.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.link)
                    Link(destination: URL(string: "https://github.com/malpern/kindaVimTutor")!) {
                        Label("github.com/malpern/kindaVimTutor", systemImage: "arrow.up.right")
                            .font(.caption)
                    }
                    .buttonStyle(.link)
                }
            }
        }
    }

    private func aboutPoint(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quinary, in: Capsule())
    }

    private var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }
}

private struct AboutWindowConfigurator: NSViewRepresentable {
    let size: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.setContentSize(size)
            window.center()
            window.isOpaque = true
            window.backgroundColor = .windowBackgroundColor
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.setContentSize(size)
            window.isOpaque = true
            window.backgroundColor = .windowBackgroundColor
        }
    }
}
