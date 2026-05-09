import Foundation

public enum YahooChartParserError: Error, Equatable, Sendable {
    case invalidJSON
    case missingResult
    case missingMeta(field: String)
    case missingPriceSeries
    case invalidPriceSeries
    case invalidQuote(field: String)
}

public struct YahooChartParser: MarketChartParsing {
    public init() {}

    public func parseStockQuoteAndHistory(data: Data, requestedSymbol: String) throws -> (quote: MarketQuote, history: HistoricalPriceSeries) {
        let payload = try decodePayload(data)
        let result = try firstResult(payload)

        let symbol = try normalizeSymbol(requestedSymbol)
        let providerSymbol = providerSymbolOrNil(raw: result.meta.symbol, normalizedSymbol: symbol)
        let displayName = normalizedName(longName: result.meta.longName, shortName: result.meta.shortName, fallbackSymbol: symbol)

        let series = try buildHistoricalSeries(
            symbol: symbol,
            providerSymbol: providerSymbol,
            rawCurrency: try requireMeta(result.meta.currency, field: "currency"),
            result: result,
            range: .twoYears
        )

        let regularMarketPrice = try requireMeta(result.meta.regularMarketPrice, field: "regularMarketPrice")
        let currentPrice = try normalizePrice(regularMarketPrice, currency: series.currency, rawCurrency: result.meta.currency ?? "")
        try validateFiniteNumber(currentPrice, field: "price")

        let metrics = try deriveQuoteMetrics(series: series, currentPrice: currentPrice)
        let dividends = try parseDividends(rawDividends: result.events?.dividends, rawCurrency: result.meta.currency ?? "")

        return (
            quote: MarketQuote(
                symbol: symbol,
                providerSymbol: providerSymbol,
                name: displayName,
                provider: .yahoo,
                price: currentPrice,
                previousClose: metrics.previousClose,
                change: metrics.change,
                changePercent: metrics.changePercent,
                currency: series.currency,
                marketTime: result.meta.regularMarketTime,
                exchangeTimezoneName: trimmedOrNil(result.meta.exchangeTimezoneName),
                change1m: metrics.change1m,
                change6m: metrics.change6m,
                change1y: metrics.change1y,
                change2y: metrics.change2y,
                dividends: dividends
            ),
            history: series
        )
    }

    public func parseCurrencyQuote(data: Data, requestedSymbol: String, displayedCurrency: String, invertForUSDDisplay: Bool) throws -> MarketQuote {
        let payload = try decodePayload(data)
        let result = try firstResult(payload)

        let symbol = try normalizeSymbol(requestedSymbol)
        let providerSymbol = providerSymbolOrNil(raw: result.meta.symbol, normalizedSymbol: symbol)
        let marketCurrency = try normalizeCurrencyCode(displayedCurrency)

        let rawPrice = try requireMeta(result.meta.regularMarketPrice, field: "regularMarketPrice")
        let rawPreviousClose = try requireMeta(result.meta.chartPreviousClose, field: "chartPreviousClose")

        let price = invertForUSDDisplay ? (1.0 / rawPrice) : rawPrice
        let previousClose = invertForUSDDisplay ? (1.0 / rawPreviousClose) : rawPreviousClose

        try validateFiniteNumber(price, field: "price")
        try validateFiniteNumber(previousClose, field: "previousClose")

        let change = price - previousClose
        let changePercent = previousClose == 0 ? 0 : (change / previousClose) * 100

        return MarketQuote(
            symbol: symbol,
            providerSymbol: providerSymbol,
            name: symbol,
            provider: .yahoo,
            price: price,
            previousClose: previousClose,
            change: change,
            changePercent: changePercent,
            currency: marketCurrency,
            marketTime: result.meta.regularMarketTime,
            exchangeTimezoneName: trimmedOrNil(result.meta.exchangeTimezoneName),
            change1m: nil,
            change6m: nil,
            change1y: nil,
            change2y: nil,
            dividends: []
        )
    }

    public func parseGoldQuoteAndHistory(quoteData: Data, historyData: Data) throws -> (quote: MarketQuote, history: HistoricalPriceSeries) {
        let quotePayload = try decodePayload(quoteData)
        let quoteResult = try firstResult(quotePayload)
        let historyPayload = try decodePayload(historyData)
        let historyResult = try firstResult(historyPayload)

        let symbol = try normalizeSymbol(YahooFinanceClient.goldSymbol)
        let providerSymbol = providerSymbolOrNil(raw: historyResult.meta.symbol, normalizedSymbol: symbol)
        let rawCurrency = try requireMeta(historyResult.meta.currency, field: "currency")

        let history = try buildHistoricalSeries(
            symbol: symbol,
            providerSymbol: providerSymbol,
            rawCurrency: rawCurrency,
            result: historyResult,
            range: .twoYears
        )

        let rawPrice = try requireMeta(quoteResult.meta.regularMarketPrice, field: "regularMarketPrice")
        let price = try normalizePrice(rawPrice, currency: history.currency, rawCurrency: rawCurrency)
        let metrics = try deriveQuoteMetrics(series: history, currentPrice: price)

        return (
            quote: MarketQuote(
                symbol: symbol,
                providerSymbol: providerSymbol,
                name: symbol,
                provider: .yahoo,
                price: price,
                previousClose: metrics.previousClose,
                change: metrics.change,
                changePercent: metrics.changePercent,
                currency: history.currency,
                marketTime: quoteResult.meta.regularMarketTime,
                exchangeTimezoneName: trimmedOrNil(quoteResult.meta.exchangeTimezoneName),
                change1m: metrics.change1m,
                change6m: metrics.change6m,
                change1y: metrics.change1y,
                change2y: metrics.change2y,
                dividends: []
            ),
            history: history
        )
    }
}
