import Foundation

struct MarketRefreshSnapshotBroadcaster {
    private var continuations: [UUID: AsyncStream<MarketRefreshSnapshot>.Continuation] = [:]

    mutating func add(
        id: UUID,
        continuation: AsyncStream<MarketRefreshSnapshot>.Continuation,
        initialSnapshot: MarketRefreshSnapshot
    ) {
        continuations[id] = continuation
        continuation.yield(initialSnapshot)
    }

    mutating func remove(id: UUID) {
        continuations[id] = nil
    }

    func emit(_ snapshot: MarketRefreshSnapshot) {
        for continuation in continuations.values {
            continuation.yield(snapshot)
        }
    }
}
