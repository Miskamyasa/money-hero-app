struct MarketRefreshCacheHydration: Sendable {
    let quotesBySymbol: [String: CachedMarketQuote]
    let historiesBySymbol: [String: CachedHistoricalPrices]

    var lastUpdatedAtMs: Int? {
        let quoteTimes = quotesBySymbol.values.map { $0.metadata.lastUpdatedAtMs }
        let historyTimes = historiesBySymbol.values.map { $0.metadata.lastUpdatedAtMs }
        return (quoteTimes + historyTimes).max()
    }
}

struct MarketRefreshCacheHydrator: Sendable {
    let cacheStore: any MarketCacheStoring
    let cacheEnvelopeFactory: MarketRefreshCacheEnvelopeFactory
    let clock: any ClockProviding

    func hydrate(symbols: [String]) async -> MarketRefreshCacheHydration {
        let nowMs = clock.nowMilliseconds()
        var quotesBySymbol: [String: CachedMarketQuote] = [:]
        var historiesBySymbol: [String: CachedHistoricalPrices] = [:]

        for symbol in symbols {
            let quoteKey = cacheEnvelopeFactory.quoteCacheKey(symbol: symbol)
            if let cachedQuote = try? await cacheStore.loadMarketQuote(key: quoteKey, nowMs: nowMs) {
                quotesBySymbol[symbol] = cachedQuote
            }

            let historyKey = cacheEnvelopeFactory.historyCacheKey(symbol: symbol)
            if let cachedHistory = try? await cacheStore.loadHistoricalPrices(key: historyKey, nowMs: nowMs) {
                historiesBySymbol[symbol] = cachedHistory
            }
        }

        return MarketRefreshCacheHydration(
            quotesBySymbol: quotesBySymbol,
            historiesBySymbol: historiesBySymbol
        )
    }
}
