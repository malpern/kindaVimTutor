import Foundation
import SwiftUI

/// Persistent user preferences for practice reminders. Stored in
/// UserDefaults so they're not affected by the Start Over action
/// (which only resets tutor progress, not app-level config).
struct NotificationPreferences {
    var dailyReminderEnabled: Bool
    /// Time-of-day for the reminder in the user's local timezone.
    /// Only hour + minute are meaningful — the date portion is
    /// discarded at scheduling time.
    var reminderTime: DateComponents

    static let defaults = NotificationPreferences(
        dailyReminderEnabled: true,
        reminderTime: DateComponents(hour: 19, minute: 30)
    )
}

/// UserDefaults-backed adapter for notification prefs. We keep the
/// same keys that `@AppStorage` uses in SettingsView so both surfaces
/// read/write the same underlying store — the SwiftUI toggle and the
/// non-View scheduling code stay in sync automatically.
enum NotificationPreferencesStorage {
    private enum Key {
        static let enabled = "notifications.dailyReminderEnabled"
        static let minutes = "notifications.reminderMinutesFromMidnight"
        static let asked = "notifications.didRequestPermission"
    }

    static func current() -> NotificationPreferences {
        let defaults = UserDefaults.standard
        // Default to enabled when the key has never been set.
        let enabled = defaults.object(forKey: Key.enabled) as? Bool ?? true
        let minutes = defaults.object(forKey: Key.minutes) as? Int ?? (19 * 60 + 30)
        return NotificationPreferences(
            dailyReminderEnabled: enabled,
            reminderTime: DateComponents(
                hour: minutes / 60,
                minute: minutes % 60
            )
        )
    }

    static var didRequestPermission: Bool {
        get { UserDefaults.standard.bool(forKey: Key.asked) }
        set { UserDefaults.standard.set(newValue, forKey: Key.asked) }
    }
}
