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

    public var isActive: Bool {
        running || completedCount < totalCount
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

public enum MarketFetchQueueError: Error, Equatable, Sendable {
    case invalidCacheKey
}
