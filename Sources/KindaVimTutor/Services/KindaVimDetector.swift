import AppKit

/// Detects whether kindaVim is installed (or just running) on this Mac.
///
/// The tutor assumes kindaVim handles Vim motions at the OS level; without
/// it, drills can't work. Install-check gates the onboarding flow; running
/// check is used for live mode indicator and welcome status.
enum KindaVimDetector {
    private static let bundleIdentifiers = [
        "mo.com.sleeplessmind.kindaVim",
        "app.kindavim.kindaVim",
        "com.godbout.kindaVim",
    ]

    static func isInstalled() -> Bool {
        bundleIdentifiers.contains { id in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil
        }
    }

    static func isRunning() -> Bool {
        bundleIdentifiers.contains { id in
            !NSRunningApplication.runningApplications(withBundleIdentifier: id).isEmpty
        }
    }
}
