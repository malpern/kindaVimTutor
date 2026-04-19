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

        checkKindaVimRunning()
        AppLogger.shared.info("modeMonitor", "startMonitoring", fields: [
            "isKindaVimRunning": isKindaVimRunning ? "1" : "0"
        ])



        // Also poll kindaVim running state + current mode once per second for
        // the first 10 seconds so we can see the state even if no broadcast
        // arrived.
        Task { @MainActor in
            for i in 0..<10 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.checkKindaVimRunning()
                AppLogger.shared.info("modeMonitor", "tick", fields: [
                    "t": String(i),
                    "running": self.isKindaVimRunning ? "1" : "0",
                    "mode": String(describing: self.currentMode),
                ])
            }
        }

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
            ) { [weak self] notification in
                let notifName = notification.name.rawValue
                MainActor.assumeIsolated {
                    AppLogger.shared.info("modeMonitor", "enterMode", fields: [
                        "name": notifName,
                        "mode": String(describing: mode)
                    ])
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
