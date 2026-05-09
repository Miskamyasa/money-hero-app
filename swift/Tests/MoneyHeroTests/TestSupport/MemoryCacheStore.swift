@testable import MoneyHero

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
