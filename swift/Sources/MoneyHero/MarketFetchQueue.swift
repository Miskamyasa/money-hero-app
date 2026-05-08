import Foundation

public struct MarketFetchQueueProgress: Equatable, Sendable {
    public let totalCount: Int
    public let completedCount: Int
    public let running: Bool
    public let currentLabel: String?

    public init(totalCount: Int, completedCount: Int, running: Bool, currentLabel: String?) {
        self.totalCount = totalCount
        self.completedCount = completedCount
        self.running = running
        self.currentLabel = currentLabel
    }
}

public struct MarketFetchQueueTask: Sendable {
    public let cacheKey: String
    public let label: String
    public let operation: @Sendable () async throws -> Void

    public init(
        cacheKey: String,
        label: String,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        self.cacheKey = cacheKey
        self.label = label
        self.operation = operation
    }
}

public actor MarketFetchQueue {
    public typealias Completion = @Sendable (Result<Void, Error>) -> Void

    private let minimumIntervalNanoseconds: UInt64 = 1_000_000_000

    private var pendingKeys: [String] = []
    private var pendingByKey: [String: PendingTask] = [:]
    private var runningTask: RunningTask?
    private var completedCount: Int = 0
    private var workerTask: Task<Void, Never>?
    private var lastTaskStartedAt: ContinuousClock.Instant?

    public init() {}

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

        if var runningTask, runningTask.task.cacheKey == normalizedKey {
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

        var pending = PendingTask(task: MarketFetchQueueTask(cacheKey: normalizedKey, label: task.label, operation: task.operation))
        if let completion {
            pending.completions.append(completion)
        }
        pendingByKey[normalizedKey] = pending
        pendingKeys.append(normalizedKey)

        ensureWorker()
        return progress
    }

    @discardableResult
    public func clearPending() -> MarketFetchQueueProgress {
        pendingKeys.removeAll()
        pendingByKey.removeAll()
        return progress
    }

    public var progress: MarketFetchQueueProgress {
        MarketFetchQueueProgress(
            totalCount: completedCount + pendingKeys.count + (runningTask == nil ? 0 : 1),
            completedCount: completedCount,
            running: runningTask != nil,
            currentLabel: runningTask?.task.label
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

            completedCount += 1
            runningTask = nil

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

        let running = RunningTask(task: pending.task, completions: pending.completions)
        runningTask = running
        return running
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

public enum MarketFetchQueueError: Error, Equatable, Sendable {
    case invalidCacheKey
}

private struct PendingTask {
    let task: MarketFetchQueueTask
    var completions: [MarketFetchQueue.Completion] = []
}

private struct RunningTask {
    let task: MarketFetchQueueTask
    var completions: [MarketFetchQueue.Completion]
}
