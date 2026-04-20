import AppKit
import ApplicationServices
import Foundation

/// Live observer for the Finder's selection. Wraps an `AXObserver`
/// bound to the Finder process so selection changes are pushed to a
/// handler instead of polled.
///
/// Notifications we care about:
///   - `AXSelectedChildrenChanged`   (icon view — bubbles up from the
///                                    scroll-area's item group)
///   - `AXSelectedRowsChanged`       (list / column view)
///   - `AXFocusedUIElementChanged`   (app-level fallback; fires when
///                                    the user tabs/clicks between
///                                    windows or changes focus)
///
/// The observer lives for the life of the caller. On `start`, it
/// installs itself on the main run loop and invokes `onChange` with
/// the newly-selected filename (or nil) whenever any of the above
/// fire. On `stop`, it unregisters and tears down.
@MainActor
final class FinderSelectionObserver {
    private var observer: AXObserver?
    private var appElement: AXUIElement?
    private var onChange: ((String?) -> Void)?

    /// Starts observing. Returns false if Finder isn't running or if
    /// AX isn't trusted — callers should surface that to the user.
    @discardableResult
    func start(onChange: @escaping (String?) -> Void) -> Bool {
        stop()
        self.onChange = onChange

        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else { return false }

        let app = AXUIElementCreateApplication(finder.processIdentifier)
        self.appElement = app

        var rawObserver: AXObserver?
        let createErr = AXObserverCreate(finder.processIdentifier,
                                          Self.callback,
                                          &rawObserver)
        guard createErr == .success, let obs = rawObserver else {
            AppLogger.shared.info("finderDrill", "observerCreateFailed",
                                  fields: ["err": "\(createErr)"])
            return false
        }
        self.observer = obs

        // Pass self through refcon so the C callback can hop back
        // into Swift. Retained here via self, not Unmanaged, because
        // the observer's lifetime is tied to this object.
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        let notes = [
            "AXSelectedChildrenChanged",
            "AXSelectedRowsChanged",
            kAXFocusedUIElementChangedNotification as String,
            kAXFocusedWindowChangedNotification as String,
        ]
        for note in notes {
            let err = AXObserverAddNotification(obs, app, note as CFString, refcon)
            if err != .success && err != .notificationAlreadyRegistered {
                AppLogger.shared.info("finderDrill", "observerAddFailed",
                                      fields: ["note": note, "err": "\(err)"])
            }
        }

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(obs),
            .defaultMode
        )

        AppLogger.shared.info("finderDrill", "observerStarted", fields: [:])
        // Deliver an initial reading so callers can sync up immediately.
        onChange(FinderDrillPrototype.readFinderSelection())
        return true
    }

    func stop() {
        if let obs = observer {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                AXObserverGetRunLoopSource(obs),
                .defaultMode
            )
        }
        observer = nil
        appElement = nil
        onChange = nil
    }

    deinit {
        // Can't call `stop()` here — it's @MainActor; deinit may not
        // be. The run loop source will be torn down when `observer`
        // deallocates; the CF memory model handles the rest.
    }

    // MARK: - C callback bridge

    private static let callback: AXObserverCallback = { _, _, _, refcon in
        guard let refcon else { return }
        let observer = Unmanaged<FinderSelectionObserver>
            .fromOpaque(refcon).takeUnretainedValue()
        Task { @MainActor in
            observer.handleNotification()
        }
    }

    private func handleNotification() {
        let name = FinderDrillPrototype.readFinderSelection()
        onChange?(name)
    }
}
