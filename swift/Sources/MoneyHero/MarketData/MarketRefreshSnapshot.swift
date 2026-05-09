public struct MarketRefreshSnapshot: Sendable {
    public let quotesBySymbol: [String: CachedMarketQuote]
    public let historiesBySymbol: [String: CachedHistoricalPrices]
    public let progress: MarketFetchQueueProgress
    public let lastUpdatedAtMs: Int?
    public let refreshErrorMessage: String?

    public init(
        quotesBySymbol: [String: CachedMarketQuote],
        historiesBySymbol: [String: CachedHistoricalPrices],
        progress: MarketFetchQueueProgress,
        lastUpdatedAtMs: Int?,
        refreshErrorMessage: String?
    ) {
        self.quotesBySymbol = quotesBySymbol
        self.historiesBySymbol = historiesBySymbol
        self.progress = progress
        self.lastUpdatedAtMs = lastUpdatedAtMs
        self.refreshErrorMessage = refreshErrorMessage
    }

    public static let empty = MarketRefreshSnapshot(
        quotesBySymbol: [:],
        historiesBySymbol: [:],
        progress: MarketFetchQueueProgress(totalCount: 0, completedCount: 0, running: false, currentLabel: nil),
        lastUpdatedAtMs: nil,
        refreshErrorMessage: nil
    )
}
