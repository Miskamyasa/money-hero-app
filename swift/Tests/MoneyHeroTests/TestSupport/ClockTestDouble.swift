@testable import MoneyHero

struct FixedClockProvider: ClockProviding {
    let nowMs: Int

    func nowMilliseconds() -> Int {
        nowMs
    }
}
