@testable import MoneyHero

extension LocalCacheMetadata {
    func withDerivedStatus(nowMs: Int) -> LocalCacheMetadata {
        LocalCacheMetadata(
            key: key,
            kind: kind,
            provider: provider,
            symbol: symbol,
            fetchedAt: fetchedAt,
            staleAt: staleAt,
            expiresAt: expiresAt,
            writtenAt: writtenAt,
            status: derivedStatus(nowMs: nowMs),
            source: .cache,
            schemaVersion: schemaVersion,
            etag: etag,
            error: error
        )
    }
}

func makeCachedQuote(symbol: String, fetchedAt: Int) -> CachedMarketQuote {
    CachedMarketQuote(
        metadata: LocalCacheMetadata(
            key: "quote:\(symbol)",
            kind: .marketQuote,
            provider: .yahoo,
            symbol: symbol,
            fetchedAt: fetchedAt,
            staleAt: fetchedAt + 1_000,
            expiresAt: fetchedAt + 2_000,
            writtenAt: fetchedAt,
            status: .fresh,
            source: .network,
            schemaVersion: 1,
            etag: nil,
            error: nil
        ),
        data: makeQuote(symbol: symbol, price: 100)
    )
}

func makeQuote(symbol: String, price: Double, currency: String = "USD") -> MarketQuote {
    MarketQuote(
        symbol: symbol,
        providerSymbol: nil,
        name: symbol,
        provider: .yahoo,
        price: price,
        previousClose: price - 1,
        change: 1,
        changePercent: 1,
        currency: currency,
        marketTime: nil,
        exchangeTimezoneName: nil,
        change1m: 1,
        change6m: 1,
        change1y: 1,
        change2y: 1,
        dividends: []
    )
}

func makeHistory(symbol: String) -> HistoricalPriceSeries {
    HistoricalPriceSeries(
        symbol: symbol,
        providerSymbol: nil,
        provider: .yahoo,
        currency: "USD",
        interval: .oneDay,
        range: .twoYears,
        prices: [
            HistoricalPrice(symbol: symbol, providerSymbol: nil, provider: .yahoo, currency: "USD", timestamp: 1, date: "1970-01-01", open: 98, high: 101, low: 97, close: 99, adjustedClose: 99, volume: 1),
            HistoricalPrice(symbol: symbol, providerSymbol: nil, provider: .yahoo, currency: "USD", timestamp: 2, date: "1970-01-02", open: 99, high: 102, low: 98, close: 100, adjustedClose: 100, volume: 1)
        ]
    )
}
