@testable import MoneyHero

actor InvocationCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

actor SnapshotCollector {
    private(set) var values: [MarketRefreshSnapshot] = []

    func append(_ snapshot: MarketRefreshSnapshot) {
        values.append(snapshot)
    }
}

actor FirstFetchGate {
    private var hasStarted = false
    private var isReleased = false
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func markStarted() {
        hasStarted = true
        startedContinuation?.resume()
        startedContinuation = nil
    }

    func waitUntilStarted() async {
        guard !hasStarted else {
            return
        }

        await withCheckedContinuation { continuation in
            startedContinuation = continuation
        }
    }

    func waitUntilReleased() async {
        guard !isReleased else {
            return
        }

        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func release() {
        isReleased = true
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}
