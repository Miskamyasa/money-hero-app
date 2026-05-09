import Foundation
@testable import MoneyHero

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
