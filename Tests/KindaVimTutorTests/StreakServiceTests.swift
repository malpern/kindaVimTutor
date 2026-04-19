import Foundation
import Testing
@testable import KindaVimTutor

@Suite("StreakService")
@MainActor
struct StreakServiceTests {
    private let cal = Calendar(identifier: .gregorian)
    private let service = StreakService(calendar: Calendar(identifier: .gregorian))

    private func date(y: Int, m: Int, d: Int, h: Int = 10) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d; comps.hour = h
        return cal.date(from: comps)!
    }

    private func progress(withResultsOn days: [Date]) -> UserProgress {
        var p = UserProgress()
        for (i, day) in days.enumerated() {
            p.completedExercises["ex.\(i)"] = ExerciseResult(
                exerciseId: "ex.\(i)",
                completedAt: day,
                timeSeconds: 1,
                keystrokeCount: 1,
                attempts: 1,
                hintsUsed: 0
            )
        }
        return p
    }

    @Test("no practice → streak 0, daysThisWeek 0")
    func empty() {
        let p = UserProgress()
        #expect(service.currentStreak(in: p, asOf: date(y: 2026, m: 4, d: 20)) == 0)
        #expect(service.daysThisWeek(in: p, asOf: date(y: 2026, m: 4, d: 20)) == 0)
    }

    @Test("three consecutive days ending today → streak 3")
    func threeInARow() {
        let p = progress(withResultsOn: [
            date(y: 2026, m: 4, d: 18),
            date(y: 2026, m: 4, d: 19),
            date(y: 2026, m: 4, d: 20),
        ])
        #expect(service.currentStreak(in: p, asOf: date(y: 2026, m: 4, d: 20)) == 3)
        #expect(service.practicedToday(in: p, asOf: date(y: 2026, m: 4, d: 20)))
    }

    @Test("streak survives if last practice was yesterday")
    func yesterdayStillAlive() {
        let p = progress(withResultsOn: [
            date(y: 2026, m: 4, d: 18),
            date(y: 2026, m: 4, d: 19),
        ])
        let streak = service.currentStreak(in: p, asOf: date(y: 2026, m: 4, d: 20))
        #expect(streak == 2)
    }

    @Test("streak broken if last practice was 2 days ago")
    func broken() {
        let p = progress(withResultsOn: [
            date(y: 2026, m: 4, d: 18),
        ])
        let streak = service.currentStreak(in: p, asOf: date(y: 2026, m: 4, d: 20))
        #expect(streak == 0)
    }

    @Test("multiple practices same day count as one day")
    func sameDayDedup() {
        let p = progress(withResultsOn: [
            date(y: 2026, m: 4, d: 20, h: 9),
            date(y: 2026, m: 4, d: 20, h: 14),
            date(y: 2026, m: 4, d: 20, h: 22),
        ])
        #expect(service.currentStreak(in: p, asOf: date(y: 2026, m: 4, d: 20)) == 1)
    }

    @Test("results before startedOverAt are excluded")
    func startOverThreshold() {
        var p = progress(withResultsOn: [
            date(y: 2026, m: 4, d: 18),
            date(y: 2026, m: 4, d: 19),
            date(y: 2026, m: 4, d: 20),
        ])
        // Reset after day 19 — only day 20 counts.
        p.startedOverAt = date(y: 2026, m: 4, d: 19, h: 23)
        #expect(service.currentStreak(in: p, asOf: date(y: 2026, m: 4, d: 20)) == 1)
    }

    @Test("reminder tier — practiced today")
    func tierToday() {
        let p = progress(withResultsOn: [date(y: 2026, m: 4, d: 20)])
        #expect(service.reminderTier(for: p, asOf: date(y: 2026, m: 4, d: 20, h: 22)) == .none)
    }

    @Test("reminder tier — 1 day away but streak < 2 stays silent")
    func tierDailyRequiresStreak() {
        let p = progress(withResultsOn: [date(y: 2026, m: 4, d: 19)])
        // Streak is 1, daysSince = 1 → tier should be .none per the
        // refinement "don't fire until streak >= 2".
        #expect(service.reminderTier(for: p, asOf: date(y: 2026, m: 4, d: 20)) == .none)
    }

    @Test("reminder tier — 1 day away with streak 3 → daily")
    func tierDaily() {
        let p = progress(withResultsOn: [
            date(y: 2026, m: 4, d: 17),
            date(y: 2026, m: 4, d: 18),
            date(y: 2026, m: 4, d: 19),
        ])
        #expect(service.reminderTier(for: p, asOf: date(y: 2026, m: 4, d: 20)) == .daily)
    }

    @Test("reminder tier — 5 days away → weekly")
    func tierWeekly() {
        let p = progress(withResultsOn: [date(y: 2026, m: 4, d: 15)])
        #expect(service.reminderTier(for: p, asOf: date(y: 2026, m: 4, d: 20)) == .weekly)
    }

    @Test("reminder tier — 30 days away → monthly")
    func tierMonthly() {
        let p = progress(withResultsOn: [date(y: 2026, m: 3, d: 21)])
        #expect(service.reminderTier(for: p, asOf: date(y: 2026, m: 4, d: 20)) == .monthly)
    }

    @Test("reminder tier — 100 days away → silent")
    func tierSilent() {
        let p = progress(withResultsOn: [date(y: 2026, m: 1, d: 10)])
        #expect(service.reminderTier(for: p, asOf: date(y: 2026, m: 4, d: 20)) == .silent)
    }
}
