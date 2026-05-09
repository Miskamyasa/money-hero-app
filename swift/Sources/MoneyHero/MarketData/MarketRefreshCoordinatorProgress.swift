extension MarketRefreshCoordinator {
    var queueCompletion: MarketFetchQueue.Completion {
        { [weak self] _ in
            guard let self else {
                return
            }
            Task {
                await self.refreshTaskCompleted()
            }
        }
    }

    func refreshTaskCompleted() async {
        progress = await fetchQueue.progress
        if refreshIsActive && refreshHasQueuedWork && !progress.isActive {
            refreshIsActive = false
            refreshHasQueuedWork = false
        }
        emitSnapshot()
    }

    func setProgressFromQueue() async {
        progress = await fetchQueue.progress
        emitSnapshot()
    }

    func queueProgressDidChange(_ progress: MarketFetchQueueProgress) {
        if refreshIsActive && !refreshHasQueuedWork && progress.totalCount == 0 && !progress.isActive {
            return
        }

        self.progress = progress
        emitSnapshot()
    }

    func observeQueueProgressIfNeeded() async {
        guard !observesQueueProgress else {
            return
        }
        observesQueueProgress = true
        await fetchQueue.setProgressObserver { [weak self] progress in
            guard let self else {
                return
            }
            Task {
                await self.queueProgressDidChange(progress)
            }
        }
    }
}
