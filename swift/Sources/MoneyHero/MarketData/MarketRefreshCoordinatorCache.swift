extension MarketRefreshCoordinator {
    func hydrateCache(symbols: [String]) async {
        let hydration = await cacheHydrator.hydrate(symbols: symbols)
        quotesBySymbol.merge(hydration.quotesBySymbol) { _, new in new }
        historiesBySymbol.merge(hydration.historiesBySymbol) { _, new in new }
        lastUpdatedAtMs = hydration.lastUpdatedAtMs
    }

    func pruneActiveSnapshots(to symbols: [String]) {
        let activeSymbols = Set(symbols)
        quotesBySymbol = quotesBySymbol.filter { activeSymbols.contains($0.key) }
        historiesBySymbol = historiesBySymbol.filter { activeSymbols.contains($0.key) }
        updateLastUpdatedFromCache()
    }

    func persistSuccess(symbol: String, quote: MarketQuote, history: HistoricalPriceSeries?) async throws {
        let nowMs = nowMilliseconds()
        let quoteEnvelope = cacheEnvelopeFactory.quoteEnvelope(symbol: symbol, quote: quote, nowMs: nowMs)

        try await cacheStore.saveMarketQuote(quoteEnvelope)
        quotesBySymbol[symbol] = quoteEnvelope

        if let history {
            let historyEnvelope = cacheEnvelopeFactory.historyEnvelope(symbol: symbol, history: history, nowMs: nowMs)

            try await cacheStore.saveHistoricalPrices(historyEnvelope)
            historiesBySymbol[symbol] = historyEnvelope
        }

        updateLastUpdatedFromCache()
        emitSnapshot()
    }

    func applyFailure(symbol: String, errorMessage: String) async {
        let nowMs = nowMilliseconds()
        let normalizedSymbol = (try? normalizeSymbol(symbol)) ?? symbol
        refreshErrorMessage = errorMessage

        if let existingQuote = quotesBySymbol[normalizedSymbol] {
            let metadata = cacheEnvelopeFactory.failedMetadata(from: existingQuote.metadata, nowMs: nowMs, errorMessage: errorMessage)
            let failedEnvelope = CachedMarketQuote(metadata: metadata, data: existingQuote.data)
            quotesBySymbol[normalizedSymbol] = failedEnvelope
            try? await cacheStore.saveMarketQuote(failedEnvelope)
        }

        if let existingHistory = historiesBySymbol[normalizedSymbol] {
            let metadata = cacheEnvelopeFactory.failedMetadata(from: existingHistory.metadata, nowMs: nowMs, errorMessage: errorMessage)
            let failedEnvelope = CachedHistoricalPrices(metadata: metadata, data: existingHistory.data)
            historiesBySymbol[normalizedSymbol] = failedEnvelope
            try? await cacheStore.saveHistoricalPrices(failedEnvelope)
        }

        updateLastUpdatedFromCache()
        emitSnapshot()
    }

    func updateLastUpdatedFromCache() {
        let quoteTimes = quotesBySymbol.values.map { $0.metadata.lastUpdatedAtMs }
        let historyTimes = historiesBySymbol.values.map { $0.metadata.lastUpdatedAtMs }
        lastUpdatedAtMs = (quoteTimes + historyTimes).max()
    }

    func quoteCacheKey(symbol: String) -> String {
        cacheEnvelopeFactory.quoteCacheKey(symbol: symbol)
    }

    func historyCacheKey(symbol: String) -> String {
        cacheEnvelopeFactory.historyCacheKey(symbol: symbol)
    }

    func nowMilliseconds() -> Int {
        clock.nowMilliseconds()
    }
}
