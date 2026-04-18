import SwiftUI

/// Inline install-status block for lesson content. If kindaVim is installed,
/// shows a green check. Otherwise a primary CTA that opens kindavim.app and
/// a re-check button that flips to the confirmation once the user returns.
struct KindaVimInstallStatusBlock: View {
    @State private var isInstalled: Bool = KindaVimDetector.isInstalled()
    private let downloadURL = URL(string: "https://kindavim.app")!

    var body: some View {
        HStack(spacing: 12) {
            if isInstalled {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("kindaVim is installed")
                        .font(.system(size: 15, weight: .semibold))
                    Text("You're ready to practice.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    NSWorkspace.shared.open(downloadURL)
                } label: {
                    HStack(spacing: 4) {
                        Text("Visit kindavim.app")
                        Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .semibold))
                    }
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            } else {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("kindaVim is not installed")
                        .font(.system(size: 15, weight: .semibold))
                    Text("You need it before the drills will work.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Button {
                        NSWorkspace.shared.open(downloadURL)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Get kindaVim").fontWeight(.semibold)
                            Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Button("Check again") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isInstalled = KindaVimDetector.isInstalled()
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isInstalled ? Color.green.opacity(0.08) : Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isInstalled ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
