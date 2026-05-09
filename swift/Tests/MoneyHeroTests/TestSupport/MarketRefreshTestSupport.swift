import Foundation
@testable import MoneyHero

actor InvocationCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

actor SnapshotCollector {
    private(set) var values: [MarketRefreshSnapshot] = []

    func append(_ snapshot: MarketRefreshSnapshot) {
        values.append(snapshot)
    }
}

actor FirstFetchGate {
    private var hasStarted = false
    private var isReleased = false
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func markStarted() {
        hasStarted = true
        startedContinuation?.resume()
        startedContinuation = nil
    }

    func waitUntilStarted() async {
        guard !hasStarted else {
            return
        }

        await withCheckedContinuation { continuation in
            startedContinuation = continuation
        }
    }

    func waitUntilReleased() async {
        guard !isReleased else {
            return
        }

        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func release() {
        isReleased = true
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

actor MemoryCacheStore: MarketCacheStoring {
    private var quotes: [String: CachedMarketQuote]
    private var histories: [String: CachedHistoricalPrices]

    init(
        quotes: [String: CachedMarketQuote] = [:],
        histories: [String: CachedHistoricalPrices] = [:]
    ) {
        self.quotes = quotes
        self.histories = histories
    }

    func saveMarketQuote(_ envelope: CachedMarketQuote) async throws {
        if let symbol = envelope.metadata.symbol {
            quotes[symbol] = envelope
        }
    }

    func saveHistoricalPrices(_ envelope: CachedHistoricalPrices) async throws {
        if let symbol = envelope.metadata.symbol {
            histories[symbol] = envelope
        }
    }

    func loadMarketQuote(key: String, nowMs: Int) async throws -> CachedMarketQuote? {
        guard let symbol = key.split(separator: ":").last.map(String.init), let quote = quotes[symbol] else {
            return nil
        }

        return CachedMarketQuote(
            metadata: quote.metadata.withDerivedStatus(nowMs: nowMs),
            data: quote.data
        )
    }

    func loadHistoricalPrices(key: String, nowMs: Int) async throws -> CachedHistoricalPrices? {
        guard let symbol = key.split(separator: ":").last.map(String.init), let history = histories[symbol] else {
            return nil
        }

        return CachedHistoricalPrices(
            metadata: history.metadata.withDerivedStatus(nowMs: nowMs),
            data: history.data
        )
    }
}

actor StubMarketDataProvider: MarketDataProviding {
    let delay: Duration
    let shouldFail: Bool

    init(delay: Duration = .milliseconds(1), shouldFail: Bool = false) {
        self.delay = delay
        self.shouldFail = shouldFail
    }

    func fetchStockChart(symbol rawSymbol: String) async throws -> YahooHTTPResponse {
        try await response(symbol: rawSymbol)
    }

    func fetchCurrencyChart(displayedCurrency rawCurrency: String) async throws -> YahooHTTPResponse {
        try await response(symbol: rawCurrency)
    }

    func fetchGoldQuoteChart() async throws -> YahooHTTPResponse {
        try await response(symbol: "GC=F")
    }

    func fetchGoldHistoryChart() async throws -> YahooHTTPResponse {
        try await response(symbol: "GC=F")
    }

    private func response(symbol: String) async throws -> YahooHTTPResponse {
        try await Task.sleep(for: delay)
        if shouldFail {
            throw StubMarketDataProviderError.failed
        }

        return YahooHTTPResponse(
            requestURL: URL(string: "https://example.com/\(symbol)")!,
            statusCode: 200,
            data: Data()
        )
    }
}

actor GatedMarketDataProvider: MarketDataProviding {
    let gate: FirstFetchGate
    private(set) var fetchCount = 0

    init(gate: FirstFetchGate) {
        self.gate = gate
    }

    func fetchStockChart(symbol rawSymbol: String) async throws -> YahooHTTPResponse {
        fetchCount += 1
        if fetchCount == 1 {
            await gate.markStarted()
            await gate.waitUntilReleased()
        }

        return YahooHTTPResponse(
            requestURL: URL(string: "https://example.com/\(rawSymbol)")!,
            statusCode: 200,
            data: Data()
        )
    }

    func fetchCurrencyChart(displayedCurrency rawCurrency: String) async throws -> YahooHTTPResponse {
        try await fetchStockChart(symbol: rawCurrency)
    }

    func fetchGoldQuoteChart() async throws -> YahooHTTPResponse {
        try await fetchStockChart(symbol: "GC=F")
    }

    func fetchGoldHistoryChart() async throws -> YahooHTTPResponse {
        try await fetchStockChart(symbol: "GC=F")
    }
}

enum StubMarketDataProviderError: Error {
    case failed
}

struct StubMarketChartParser: MarketChartParsing {
    func parseStockQuoteAndHistory(data: Data, requestedSymbol: String) throws -> (quote: MarketQuote, history: HistoricalPriceSeries) {
        let symbol = try normalizeSymbol(requestedSymbol)
        return (makeQuote(symbol: symbol, price: 101), makeHistory(symbol: symbol))
    }

    func parseCurrencyQuote(data: Data, requestedSymbol: String, displayedCurrency: String, invertForUSDDisplay: Bool) throws -> MarketQuote {
        try makeQuote(symbol: normalizeSymbol(requestedSymbol), price: 3.7, currency: displayedCurrency)
    }

    func parseGoldQuoteAndHistory(quoteData: Data, historyData: Data) throws -> (quote: MarketQuote, history: HistoricalPriceSeries) {
        (makeQuote(symbol: "GC=F", price: 2_300), makeHistory(symbol: "GC=F"))
    }
}

struct FixedClockProvider: ClockProviding {
    let nowMs: Int

    func nowMilliseconds() -> Int {
        nowMs
    }
}

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
