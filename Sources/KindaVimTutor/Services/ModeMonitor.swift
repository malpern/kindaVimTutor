import SwiftUI
import AppKit

@Observable
@MainActor
final class ModeMonitor {
    private(set) var currentMode: VimMode = .unknown
    private(set) var isKindaVimRunning: Bool = false

    private var observers: [NSObjectProtocol] = []

    func startMonitoring() {
        let center = DistributedNotificationCenter.default()

        let enterMappings: [(String, VimMode)] = [
            ("kindaVimDidEnterNormalMode", .normal),
            ("kindaVimDidEnterInsertMode", .insert),
            ("kindaVimDidEnterVisualMode", .visual),
        ]

        for (name, mode) in enterMappings {
            let observer = center.addObserver(
                forName: Notification.Name(name),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.currentMode = mode
                    self?.isKindaVimRunning = true
                }
            }
            observers.append(observer)
        }

        // Exit notifications
        let exitMappings = [
            "kindaVimDidExitNormalMode",
            "kindaVimDidExitInsertMode",
            "kindaVimDidExitVisualMode",
            "kindaVimDidExitOperatorPendingMode",
        ]

        for name in exitMappings {
            let observer = center.addObserver(
                forName: Notification.Name(name),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.isKindaVimRunning = true
                }
            }
            observers.append(observer)
        }

        checkKindaVimRunning()
    }

    func stopMonitoring() {
        for observer in observers {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        observers.removeAll()
    }

    func checkKindaVimRunning() {
        // Try common bundle identifiers for kindaVim
        let bundleIds = [
            "mo.com.sleeplessmind.kindaVim",
            "app.kindavim.kindaVim",
            "com.godbout.kindaVim",
        ]
        isKindaVimRunning = bundleIds.contains { id in
            !NSRunningApplication.runningApplications(withBundleIdentifier: id).isEmpty
        }
    }
}
