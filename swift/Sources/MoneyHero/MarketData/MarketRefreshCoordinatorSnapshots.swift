import Foundation

extension MarketRefreshCoordinator {
    func addSnapshotContinuation(id: UUID, continuation: AsyncStream<MarketRefreshSnapshot>.Continuation) {
        snapshotBroadcaster.add(id: id, continuation: continuation, initialSnapshot: snapshot())
    }

    func removeSnapshotContinuation(id: UUID) {
        snapshotBroadcaster.remove(id: id)
    }

    func emitSnapshot() {
        snapshotBroadcaster.emit(snapshot())
    }
}
