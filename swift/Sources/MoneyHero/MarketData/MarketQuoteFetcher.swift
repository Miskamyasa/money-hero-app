struct MarketQuoteFetchResult: Sendable {
    let symbol: String
    let quote: MarketQuote
    let history: HistoricalPriceSeries?
}

struct MarketQuoteFetcher: Sendable {
    private let provider: any MarketDataProviding
    private let parser: any MarketChartParsing
    private let goldSymbol = YahooFinanceClient.goldSymbol

    init(provider: any MarketDataProviding, parser: any MarketChartParsing) {
        self.provider = provider
        self.parser = parser
    }

    func fetch(symbol rawSymbol: String, kind: MarketRefreshTrackedSymbolKind) async throws -> MarketQuoteFetchResult {
        let symbol = try normalizeSymbol(rawSymbol)

        switch kind {
        case .currency:
            return try await fetchCurrency(symbol: symbol)
        case .market where symbol == goldSymbol:
            return try await fetchGold(symbol: symbol)
        case .market:
            return try await fetchStock(symbol: symbol)
        }
    }

    private func fetchCurrency(symbol: String) async throws -> MarketQuoteFetchResult {
        if symbol == "USD" {
            return try await fetchUSDIndex()
        }

        let response = try await provider.fetchCurrencyChart(displayedCurrency: symbol)
        let quote = try parser.parseCurrencyQuote(
            data: response.data,
            requestedSymbol: symbol,
            displayedCurrency: symbol,
            invertForUSDDisplay: true
        )
        return MarketQuoteFetchResult(symbol: symbol, quote: quote, history: nil)
    }

    private func fetchUSDIndex() async throws -> MarketQuoteFetchResult {
        let indexSymbol = YahooFinanceClient.usDollarIndexSymbol
        let response = try await provider.fetchStockChart(symbol: indexSymbol)
        let parsed = try parser.parseStockQuoteAndHistory(data: response.data, requestedSymbol: indexSymbol)
        let quote = fixedUSDQuote(from: parsed.quote, indexSymbol: indexSymbol)
        return MarketQuoteFetchResult(symbol: "USD", quote: quote, history: nil)
    }

    private func fetchGold(symbol: String) async throws -> MarketQuoteFetchResult {
        let quoteResponse = try await provider.fetchGoldQuoteChart()
        let historyResponse = try await provider.fetchGoldHistoryChart()
        let parsed = try parser.parseGoldQuoteAndHistory(
            quoteData: quoteResponse.data,
            historyData: historyResponse.data
        )
        return MarketQuoteFetchResult(symbol: symbol, quote: parsed.quote, history: parsed.history)
    }

    private func fetchStock(symbol: String) async throws -> MarketQuoteFetchResult {
        let response = try await provider.fetchStockChart(symbol: symbol)
        let parsed = try parser.parseStockQuoteAndHistory(data: response.data, requestedSymbol: symbol)
        return MarketQuoteFetchResult(symbol: symbol, quote: parsed.quote, history: parsed.history)
    }

    private func fixedUSDQuote(from indexQuote: MarketQuote, indexSymbol: String) -> MarketQuote {
        let previousClose = fixedPreviousClose(changePercent: indexQuote.changePercent)
        return MarketQuote(
            symbol: "USD",
            providerSymbol: indexQuote.providerSymbol ?? indexSymbol,
            name: "US Dollar Index",
            provider: indexQuote.provider,
            price: 1,
            previousClose: previousClose,
            change: 1 - previousClose,
            changePercent: indexQuote.changePercent,
            currency: "USD",
            marketTime: indexQuote.marketTime,
            exchangeTimezoneName: indexQuote.exchangeTimezoneName,
            change1m: indexQuote.change1m,
            change6m: indexQuote.change6m,
            change1y: indexQuote.change1y,
            change2y: indexQuote.change2y,
            dividends: []
        )
    }

    private func fixedPreviousClose(changePercent: Double) -> Double {
        let denominator = 1 + (changePercent / 100)
        guard denominator.isFinite, denominator > 0 else {
            return 1
        }

        return 1 / denominator
    }
}
