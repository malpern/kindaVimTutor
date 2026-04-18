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

        // Catch-all diagnostic: log every distributed notification whose
        // name contains "kindaVim" (case-insensitive) so we can see what the
        // actual broadcast names are if the ones above are wrong.
        let catchAll = center.addObserver(
            forName: nil,
            object: nil,
            queue: .main
        ) { notification in
            let n = notification.name.rawValue
            guard n.range(of: "kindavim", options: .caseInsensitive) != nil else { return }
            let objDesc = String(describing: notification.object)
            let userDesc = String(describing: notification.userInfo ?? [:])
            AppLogger.shared.info("modeMonitor", "distNotifSeen", fields: [
                "name": n,
                "object": objDesc,
                "userInfo": userDesc
            ])
        }
        observers.append(catchAll)

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
