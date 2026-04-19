import Foundation
import UserNotifications
import AppKit

/// Schedules the single "come back and practice" reminder based on
/// the student's current streak tier. Honors the Settings toggle and
/// user-chosen reminder time.
///
/// Design: one outstanding notification at a time, identified by a
/// constant request id. Any `rescheduleIfNeeded()` call cancels the
/// existing request and schedules a fresh one — cheap and idempotent.
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let streak = StreakService()
    private let requestID = "kvt.streak.reminder"

    /// True when we're running inside `swift test` or any environment
    /// where `UNUserNotificationCenter.current()` would raise a
    /// bundle-proxy-missing NSException. Notifications are a no-op in
    /// that case — the unit tests don't need them and the crash
    /// otherwise takes down the whole suite.
    private var isTestEnvironment: Bool {
        NSClassFromString("XCTest") != nil
            || Bundle.main.bundleIdentifier == nil
            || Bundle.main.bundleURL.path.contains(".xctoolchain")
    }

    // MARK: - Permission

    /// Request authorization once. Safe to call repeatedly — the
    /// system caches the result after the first prompt.
    func requestAuthorizationIfNeeded() async {
        guard !isTestEnvironment else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
        AppLogger.shared.info("notifications", "permissionRequested", fields: [:])
    }

    // MARK: - Scheduling

    /// Cancel any pending reminder and (if the tier + prefs allow)
    /// schedule the next one. Call this after every state change:
    /// app launch, exercise completion, settings change.
    func rescheduleIfNeeded(progress: UserProgress,
                            prefs: NotificationPreferences) async {
        guard !isTestEnvironment else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestID])

        guard prefs.dailyReminderEnabled else {
            AppLogger.shared.info("notifications", "disabled", fields: [:])
            return
        }

        // Only schedule if the system actually allows notifications.
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else {
            return
        }

        let tier = streak.reminderTier(for: progress)
        guard let delayDays = tier.nextDelayDays else {
            AppLogger.shared.info("notifications", "silent", fields: [
                "tier": String(describing: tier),
            ])
            return
        }

        guard let fireDate = nextFireDate(
            delayDays: delayDays,
            reminderTime: prefs.reminderTime
        ) else { return }

        let content = content(for: tier, progress: progress)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            ),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: requestID,
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
            AppLogger.shared.info("notifications", "scheduled", fields: [
                "tier": String(describing: tier),
                "fireAt": ISO8601DateFormatter().string(from: fireDate),
            ])
        } catch {
            AppLogger.shared.error("notifications", "scheduleFailed", fields: [
                "error": String(describing: error),
            ])
        }
    }

    /// Cancel any pending reminder without scheduling a new one.
    func cancelAll() {
        guard !isTestEnvironment else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [requestID])
    }

    // MARK: - Helpers

    /// The next calendar instant that is at `reminderTime` local and
    /// at least `delayDays` days from now. For daily (delayDays = 1),
    /// that's tomorrow at the user's chosen time unless today's slot
    /// hasn't happened yet AND they haven't practiced — in which case
    /// fire today.
    private func nextFireDate(delayDays: Int,
                              reminderTime: DateComponents) -> Date? {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        var target = cal.date(byAdding: .day, value: delayDays - 1, to: today)!

        var comps = cal.dateComponents([.year, .month, .day], from: target)
        comps.hour = reminderTime.hour ?? 19
        comps.minute = reminderTime.minute ?? 30

        guard var fire = cal.date(from: comps) else { return nil }
        // If that instant is already in the past (e.g. daily reminder
        // for today and it's already 8 PM), bump forward a day.
        if fire <= now {
            target = cal.date(byAdding: .day, value: 1, to: target)!
            comps = cal.dateComponents([.year, .month, .day], from: target)
            comps.hour = reminderTime.hour ?? 19
            comps.minute = reminderTime.minute ?? 30
            fire = cal.date(from: comps) ?? fire
        }
        return fire
    }

    private func content(for tier: StreakService.ReminderTier,
                          progress: UserProgress) -> UNNotificationContent {
        let streakCount = streak.currentStreak(in: progress)
        let c = UNMutableNotificationContent()
        c.sound = .default

        switch tier {
        case .daily:
            c.title = "Keep your \(streakCount)-day streak alive"
            c.body = "A few minutes in kindaVim Tutor and you're set for today."
        case .weekly:
            c.title = "Still with us?"
            c.body = "Come back and pick up where you left off."
        case .monthly:
            c.title = "kindaVim Tutor is still here"
            c.body = "Five minutes of practice when you're ready."
        case .none, .silent:
            c.title = ""
        }
        return c
    }
}
