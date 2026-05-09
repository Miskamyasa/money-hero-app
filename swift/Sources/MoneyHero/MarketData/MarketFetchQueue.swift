import Foundation

public actor MarketFetchQueue {
    public typealias Completion = @Sendable (Result<Void, Error>) -> Void
    public typealias ProgressObserver = @Sendable (MarketFetchQueueProgress) -> Void

    private let minimumIntervalNanoseconds: UInt64 = 1_000_000_000

    private var pendingKeys: [String] = []
    private var pendingByKey: [String: PendingTask] = [:]
    private var runningTask: RunningTask?
    private var completedCount: Int = 0
    private var workerTask: Task<Void, Never>?
    private var lastTaskStartedAt: ContinuousClock.Instant?
    private var progressObserver: ProgressObserver?
    private var generation: Int = 0

    public init() {}

    public func setProgressObserver(_ observer: ProgressObserver?) {
        progressObserver = observer
        notifyProgressChanged()
    }

    @discardableResult
    public func enqueue(task: MarketFetchQueueTask, completion: Completion? = nil) -> MarketFetchQueueProgress {
        let normalizedKey = task.cacheKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else {
            if let completion {
                Task {
                    completion(.failure(MarketFetchQueueError.invalidCacheKey))
                }
            }
            return progress
        }

        if var runningTask, runningTask.task.cacheKey == normalizedKey, runningTask.generation == generation {
            if let completion {
                runningTask.completions.append(completion)
                self.runningTask = runningTask
            }
            return progress
        }

        if var pending = pendingByKey[normalizedKey] {
            if let completion {
                pending.completions.append(completion)
                pendingByKey[normalizedKey] = pending
            }
            return progress
        }

        var pending = PendingTask(
            task: MarketFetchQueueTask(cacheKey: normalizedKey, label: task.label, operation: task.operation),
            generation: generation
        )
        if let completion {
            pending.completions.append(completion)
        }
        pendingByKey[normalizedKey] = pending
        pendingKeys.append(normalizedKey)

        ensureWorker()
        notifyProgressChanged()
        return progress
    }

    @discardableResult
    public func clearPending(resetCompletedCount: Bool = false) -> MarketFetchQueueProgress {
        generation += 1
        pendingKeys.removeAll()
        pendingByKey.removeAll()
        if resetCompletedCount {
            completedCount = 0
        }
        notifyProgressChanged()
        return progress
    }

    public var progress: MarketFetchQueueProgress {
        let currentPendingCount = pendingByKey.values.filter { $0.generation == generation }.count
        let currentRunningTask = runningTask?.generation == generation ? runningTask : nil
        return MarketFetchQueueProgress(
            totalCount: completedCount + currentPendingCount + (currentRunningTask == nil ? 0 : 1),
            completedCount: completedCount,
            running: currentRunningTask != nil,
            currentLabel: currentRunningTask?.task.label
        )
    }

    private func ensureWorker() {
        guard workerTask == nil else {
            return
        }

        workerTask = Task {
            await runQueueLoop()
        }
    }

    private func runQueueLoop() async {
        while true {
            guard let next = dequeueNextTask() else {
                workerTask = nil
                return
            }

            await waitForMinimumIntervalSinceLastStart()
            lastTaskStartedAt = .now

            let result: Result<Void, Error>
            do {
                try await next.task.operation()
                result = .success(())
            } catch {
                result = .failure(error)
            }

            if next.generation == generation {
                completedCount += 1
            }
            runningTask = nil
            notifyProgressChanged()

            for completion in next.completions {
                Task {
                    completion(result)
                }
            }
        }
    }

    private func dequeueNextTask() -> RunningTask? {
        guard let firstKey = pendingKeys.first else {
            return nil
        }

        pendingKeys.removeFirst()
        guard let pending = pendingByKey.removeValue(forKey: firstKey) else {
            return nil
        }

        let running = RunningTask(task: pending.task, completions: pending.completions, generation: pending.generation)
        runningTask = running
        notifyProgressChanged()
        return running
    }

    private func notifyProgressChanged() {
        progressObserver?(progress)
    }

    private func waitForMinimumIntervalSinceLastStart() async {
        guard let lastTaskStartedAt else {
            return
        }

        let elapsed = lastTaskStartedAt.duration(to: .now)
        let minimum = Duration.nanoseconds(Int64(minimumIntervalNanoseconds))
        guard elapsed < minimum else {
            return
        }

        let remaining = minimum - elapsed
        try? await Task.sleep(for: remaining)
    }
}

private struct PendingTask {
    let task: MarketFetchQueueTask
    let generation: Int
    var completions: [MarketFetchQueue.Completion] = []
}

private struct RunningTask {
    let task: MarketFetchQueueTask
    var completions: [MarketFetchQueue.Completion]
    let generation: Int
}
