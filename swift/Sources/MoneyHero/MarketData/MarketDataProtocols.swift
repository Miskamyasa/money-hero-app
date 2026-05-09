import Foundation

public protocol MarketCacheStoring: Sendable {
    func saveMarketQuote(_ envelope: CachedMarketQuote) async throws
    func saveHistoricalPrices(_ envelope: CachedHistoricalPrices) async throws
    func loadMarketQuote(key: String, nowMs: Int) async throws -> CachedMarketQuote?
    func loadHistoricalPrices(key: String, nowMs: Int) async throws -> CachedHistoricalPrices?
}

public protocol MarketDataProviding: Sendable {
    func fetchStockChart(symbol rawSymbol: String) async throws -> YahooHTTPResponse
    func fetchCurrencyChart(displayedCurrency rawCurrency: String) async throws -> YahooHTTPResponse
    func fetchGoldQuoteChart() async throws -> YahooHTTPResponse
    func fetchGoldHistoryChart() async throws -> YahooHTTPResponse
}

public protocol MarketChartParsing: Sendable {
    func parseStockQuoteAndHistory(data: Data, requestedSymbol: String) throws -> (quote: MarketQuote, history: HistoricalPriceSeries)
    func parseCurrencyQuote(data: Data, requestedSymbol: String, displayedCurrency: String, invertForUSDDisplay: Bool) throws -> MarketQuote
    func parseGoldQuoteAndHistory(quoteData: Data, historyData: Data) throws -> (quote: MarketQuote, history: HistoricalPriceSeries)
}

public protocol ClockProviding: Sendable {
    func nowMilliseconds() -> Int
}

public struct SystemClockProvider: ClockProviding {
    public init() {}

    public func nowMilliseconds() -> Int {
        Int(Date().timeIntervalSince1970 * 1000)
    }
}
