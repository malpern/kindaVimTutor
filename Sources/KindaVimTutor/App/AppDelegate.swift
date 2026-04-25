import AppKit

/// Strips the macOS system Help menu from the main menu bar and
/// keeps it stripped. Without a persistent observer, SwiftUI can
/// re-install the Help menu after our initial removal (commands
/// rebuild, menu item validation, etc.), and the system Help menu
/// ignores custom `⌘?` shortcuts + shows a Spotlight search field
/// indexed on Apple Help Book content we don't ship.
///
/// Using an `NSApplicationDelegateAdaptor` lets us hook
/// `applicationDidFinishLaunching` (after SwiftUI's menu setup
/// runs) plus `NSMenu.didChangeItemNotification` so the Help menu
/// stays gone across the app's lifetime.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        stripHelpMenu()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuDidChange),
            name: NSMenu.didChangeItemNotification,
            object: nil
        )
    }

    @objc private func menuDidChange(_ note: Notification) {
        stripHelpMenu()
    }

    private func stripHelpMenu() {
        guard let mainMenu = NSApp.mainMenu else { return }
        while let helpItem = mainMenu.items.first(where: {
            $0.submenu?.title == "Help"
                || $0.title == "Help"
        }) {
            mainMenu.removeItem(helpItem)
        }
        NSApp.helpMenu = nil
    }
}
