import Foundation

/// Computes streak and activity metrics from `UserProgress`.
/// Pure derivation — no storage. Called by ProgressStore and the
/// notification scheduler to decide what to show and when to remind.
struct StreakService {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Practice days

    /// Distinct days the student completed at least one exercise AFTER
    /// any `startedOverAt` threshold. Keyed by day-start in the local
    /// calendar so "this morning's work" and "last night's work"
    /// collapse correctly.
    func practiceDays(in progress: UserProgress) -> Set<Date> {
        var days: Set<Date> = []
        for result in progress.completedExercises.values {
            if let threshold = progress.startedOverAt,
               result.completedAt <= threshold {
                continue
            }
            days.insert(calendar.startOfDay(for: result.completedAt))
        }
        return days
    }

    // MARK: - Current streak

    /// Consecutive practice days ending today (or yesterday — the
    /// streak is still alive until midnight of the day AFTER the last
    /// practice day).
    func currentStreak(in progress: UserProgress,
                        asOf now: Date = Date()) -> Int {
        let days = practiceDays(in: progress)
        guard !days.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // If the most recent practice day is before yesterday, the
        // streak is already broken.
        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }

    func practicedToday(in progress: UserProgress,
                        asOf now: Date = Date()) -> Bool {
        let today = calendar.startOfDay(for: now)
        return practiceDays(in: progress).contains(today)
    }

    /// Days since the last practice (0 if practiced today, 1 if
    /// yesterday, etc.). Returns nil if the student has never
    /// practiced.
    func daysSinceLastPractice(in progress: UserProgress,
                                asOf now: Date = Date()) -> Int? {
        guard let last = practiceDays(in: progress).max() else { return nil }
        let today = calendar.startOfDay(for: now)
        let delta = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        return max(delta, 0)
    }

    // MARK: - Days this week (for the toolbar ring)

    /// Count of distinct practice days in the current calendar week
    /// (Mon-Sun or Sun-Sat depending on locale). Returns 0..7.
    func daysThisWeek(in progress: UserProgress,
                      asOf now: Date = Date()) -> Int {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return 0
        }
        let weekEndExclusive = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        return practiceDays(in: progress).filter { day in
            day >= weekStart && day < weekEndExclusive
        }.count
    }

    // MARK: - Notification tier

    /// What cadence of reminder to schedule next, given the current
    /// activity state. The tiers step down gracefully the longer the
    /// student stays away, then go silent at 90+ days.
    enum ReminderTier: Equatable {
        case none            // practiced today — nothing to remind about
        case daily           // 1-2 days since last practice, streak worth protecting
        case weekly          // 3-20 days
        case monthly         // 21-89 days
        case silent          // 90+ days — stop pestering

        var nextDelayDays: Int? {
            switch self {
            case .none:    return nil
            case .daily:   return 1
            case .weekly:  return 7
            case .monthly: return 30
            case .silent:  return nil
            }
        }
    }

    func reminderTier(for progress: UserProgress,
                      asOf now: Date = Date()) -> ReminderTier {
        guard let daysSince = daysSinceLastPractice(in: progress, asOf: now) else {
            // First-time user — no practice yet. Don't start pinging
            // them; they just installed the app.
            return .none
        }
        let streak = currentStreak(in: progress, asOf: now)
        switch daysSince {
        case 0:
            return .none
        case 1...2:
            // Only "defend the streak" if there's a streak worth
            // defending. Below 2 days, stay silent — the loss-aversion
            // framing doesn't work and it feels nagging.
            return streak >= 2 ? .daily : .none
        case 3...20:
            return .weekly
        case 21...89:
            return .monthly
        default:
            return .silent
        }
    }
}
