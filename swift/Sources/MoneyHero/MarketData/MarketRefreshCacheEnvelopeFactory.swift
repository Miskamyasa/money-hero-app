struct MarketRefreshCacheEnvelopeFactory: Sendable {
    let schemaVersion: Int
    let quoteStaleAfterMs: Int
    let quoteExpiresAfterMs: Int
    let historyStaleAfterMs: Int
    let historyExpiresAfterMs: Int

    func quoteCacheKey(symbol: String) -> String {
        "quote:\(symbol)"
    }

    func historyCacheKey(symbol: String) -> String {
        "history:\(symbol)"
    }

    func quoteEnvelope(symbol: String, quote: MarketQuote, nowMs: Int) -> CachedMarketQuote {
        CachedMarketQuote(
            metadata: successMetadata(
                key: quoteCacheKey(symbol: symbol),
                kind: .marketQuote,
                symbol: symbol,
                nowMs: nowMs,
                staleAfterMs: quoteStaleAfterMs,
                expiresAfterMs: quoteExpiresAfterMs
            ),
            data: quote
        )
    }

    func historyEnvelope(symbol: String, history: HistoricalPriceSeries, nowMs: Int) -> CachedHistoricalPrices {
        CachedHistoricalPrices(
            metadata: successMetadata(
                key: historyCacheKey(symbol: symbol),
                kind: .historicalPrices,
                symbol: symbol,
                nowMs: nowMs,
                staleAfterMs: historyStaleAfterMs,
                expiresAfterMs: historyExpiresAfterMs
            ),
            data: history
        )
    }

    func failedMetadata(from metadata: LocalCacheMetadata, nowMs: Int, errorMessage: String) -> LocalCacheMetadata {
        LocalCacheMetadata(
            key: metadata.key,
            kind: metadata.kind,
            provider: metadata.provider,
            symbol: metadata.symbol,
            fetchedAt: metadata.fetchedAt,
            staleAt: metadata.staleAt,
            expiresAt: metadata.expiresAt,
            writtenAt: nowMs,
            status: .error,
            source: .cache,
            schemaVersion: metadata.schemaVersion,
            etag: metadata.etag,
            error: errorMessage
        )
    }

    private func successMetadata(
        key: String,
        kind: CacheKind,
        symbol: String,
        nowMs: Int,
        staleAfterMs: Int,
        expiresAfterMs: Int
    ) -> LocalCacheMetadata {
        LocalCacheMetadata(
            key: key,
            kind: kind,
            provider: .yahoo,
            symbol: symbol,
            fetchedAt: nowMs,
            staleAt: nowMs + staleAfterMs,
            expiresAt: nowMs + expiresAfterMs,
            writtenAt: nowMs,
            status: .fresh,
            source: .network,
            schemaVersion: schemaVersion,
            etag: nil,
            error: nil
        )
    }
}
