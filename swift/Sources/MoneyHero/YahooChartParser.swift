import Foundation

public enum YahooChartParserError: Error, Equatable, Sendable {
    case invalidJSON
    case missingResult
    case missingMeta(field: String)
    case missingPriceSeries
    case invalidPriceSeries
    case invalidQuote(field: String)
}

public struct YahooChartParser {
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

    private func decodePayload(_ data: Data) throws -> YahooChartPayload {
        do {
            return try JSONDecoder().decode(YahooChartPayload.self, from: data)
        } catch {
            throw YahooChartParserError.invalidJSON
        }
    }

    private func firstResult(_ payload: YahooChartPayload) throws -> YahooChartResult {
        guard let result = payload.chart.result?.first else {
            throw YahooChartParserError.missingResult
        }
        return result
    }

    private func buildHistoricalSeries(
        symbol: String,
        providerSymbol: String?,
        rawCurrency: String,
        result: YahooChartResult,
        range: HistoricalPriceRange
    ) throws -> HistoricalPriceSeries {
        let currency = try normalizeCurrencyAndPrice(currency: rawCurrency, price: 1).currency
        guard let timestamps = result.timestamp, !timestamps.isEmpty else {
            throw YahooChartParserError.missingPriceSeries
        }
        guard let quote = result.indicators.quote.first else {
            throw YahooChartParserError.missingPriceSeries
        }

        let adjustedClose = result.indicators.adjclose.first?.adjclose ?? []
        var prices: [HistoricalPrice] = []
        prices.reserveCapacity(timestamps.count)

        for index in timestamps.indices {
            let timestamp = timestamps[index]
            guard let rawClose = value(at: index, from: quote.close) else {
                continue
            }

            let close = try normalizePrice(rawClose, currency: currency, rawCurrency: rawCurrency)
            guard close > 0 else {
                continue
            }

            let open = try normalizeOptionalPrice(value(at: index, from: quote.open), currency: currency, rawCurrency: rawCurrency)
            let high = try normalizeOptionalPrice(value(at: index, from: quote.high), currency: currency, rawCurrency: rawCurrency)
            let low = try normalizeOptionalPrice(value(at: index, from: quote.low), currency: currency, rawCurrency: rawCurrency)
            let adj = try normalizeOptionalPrice(value(at: index, from: adjustedClose), currency: currency, rawCurrency: rawCurrency)
            let volume = normalizedVolume(value(at: index, from: quote.volume))

            prices.append(
                HistoricalPrice(
                    symbol: symbol,
                    providerSymbol: providerSymbol,
                    provider: .yahoo,
                    currency: currency,
                    timestamp: timestamp,
                    date: utcDateString(fromUnixSeconds: timestamp),
                    open: open,
                    high: high,
                    low: low,
                    close: close,
                    adjustedClose: adj,
                    volume: volume
                )
            )
        }

        let sorted = prices.sorted { $0.timestamp < $1.timestamp }
        guard !sorted.isEmpty else {
            throw YahooChartParserError.invalidPriceSeries
        }

        return HistoricalPriceSeries(
            symbol: symbol,
            providerSymbol: providerSymbol,
            provider: .yahoo,
            currency: currency,
            interval: .oneDay,
            range: range,
            prices: sorted
        )
    }

    private func deriveQuoteMetrics(series: HistoricalPriceSeries, currentPrice: Double) throws -> (previousClose: Double, change: Double, changePercent: Double, change1m: Double?, change6m: Double?, change1y: Double?, change2y: Double?) {
        let closes = series.prices.map(\.close)
        guard let latestClose = closes.last else {
            throw YahooChartParserError.invalidPriceSeries
        }

        let previousClose = closes.dropLast().last ?? latestClose
        let change = currentPrice - previousClose
        let changePercent = previousClose == 0 ? 0 : (change / previousClose) * 100

        let anchor1m = anchorPercentChange(series: series, monthsAgo: 1, currentPrice: currentPrice)
        let anchor6m = anchorPercentChange(series: series, monthsAgo: 6, currentPrice: currentPrice)
        let anchor1y = anchorPercentChange(series: series, yearsAgo: 1, currentPrice: currentPrice)
        let anchor2y = anchorPercentChange(series: series, yearsAgo: 2, currentPrice: currentPrice)

        return (previousClose, change, changePercent, anchor1m, anchor6m, anchor1y, anchor2y)
    }

    private func anchorPercentChange(series: HistoricalPriceSeries, monthsAgo: Int? = nil, yearsAgo: Int? = nil, currentPrice: Double) -> Double? {
        guard let latestTimestamp = series.prices.last?.timestamp else {
            return nil
        }

        var components = DateComponents()
        if let monthsAgo {
            components.month = -monthsAgo
        }
        if let yearsAgo {
            components.year = -yearsAgo
        }

        let calendar = Calendar(identifier: .gregorian)
        let latestDate = Date(timeIntervalSince1970: TimeInterval(latestTimestamp))
        guard let anchorDate = calendar.date(byAdding: components, to: latestDate) else {
            return nil
        }

        let anchorTimestamp = Int(anchorDate.timeIntervalSince1970)
        guard let baseClose = series.prices.last(where: { $0.timestamp <= anchorTimestamp })?.close else {
            return nil
        }

        guard baseClose != 0 else {
            return 0
        }

        return ((currentPrice - baseClose) / baseClose) * 100
    }

    private func parseDividends(rawDividends: [String: YahooDividendEvent]?, rawCurrency: String) throws -> [DividendEvent] {
        guard let rawDividends else {
            return []
        }

        var events: [DividendEvent] = []
        events.reserveCapacity(rawDividends.count)

        for (_, event) in rawDividends {
            let amount = try normalizePrice(event.amount, currency: "", rawCurrency: rawCurrency)
            events.append(DividendEvent(amount: amount, date: event.date))
        }

        return events.sorted { $0.date < $1.date }
    }

    private func requireMeta(_ value: Double?, field: String) throws -> Double {
        guard let value else {
            throw YahooChartParserError.missingMeta(field: field)
        }
        try validateFiniteNumber(value, field: field)
        return value
    }

    private func requireMeta(_ value: String?, field: String) throws -> String {
        guard let value else {
            throw YahooChartParserError.missingMeta(field: field)
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw YahooChartParserError.missingMeta(field: field)
        }
        return trimmed
    }

    private func normalizePrice(_ value: Double, currency: String, rawCurrency: String) throws -> Double {
        let normalized: Double
        if currency.isEmpty {
            normalized = try normalizeCurrencyAndPrice(currency: rawCurrency, price: value).price
        } else {
            let raw = rawCurrency.trimmingCharacters(in: .whitespacesAndNewlines)
            switch raw {
            case "GBp", "ILA":
                normalized = value / 100
            default:
                normalized = value
            }
        }

        try validateFiniteNumber(normalized, field: "price")
        return normalized
    }

    private func normalizeOptionalPrice(_ value: Double?, currency: String, rawCurrency: String) throws -> Double? {
        guard let value else {
            return nil
        }
        return try normalizePrice(value, currency: currency, rawCurrency: rawCurrency)
    }

    private func normalizedVolume(_ value: Double?) -> Int? {
        guard let value, value.isFinite, value >= 0 else {
            return nil
        }
        return Int(value)
    }

    private func utcDateString(fromUnixSeconds seconds: Int) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
    }

    private func trimmedOrNil(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func normalizedName(longName: String?, shortName: String?, fallbackSymbol: String) -> String {
        if let longName = trimmedOrNil(longName) {
            return longName
        }
        if let shortName = trimmedOrNil(shortName) {
            return shortName
        }
        return fallbackSymbol
    }

    private func providerSymbolOrNil(raw: String?, normalizedSymbol: String) -> String? {
        guard let raw = trimmedOrNil(raw) else {
            return nil
        }
        return raw.uppercased() == normalizedSymbol ? nil : raw
    }

    private func value(at index: Int, from values: [Double?]) -> Double? {
        guard index < values.count else {
            return nil
        }
        return values[index]
    }
}

private struct YahooChartPayload: Decodable {
    let chart: YahooChartContainer
}

private struct YahooChartContainer: Decodable {
    let result: [YahooChartResult]?
}

private struct YahooChartResult: Decodable {
    let meta: YahooChartMeta
    let timestamp: [Int]?
    let indicators: YahooChartIndicators
    let events: YahooChartEvents?
}

private struct YahooChartMeta: Decodable {
    let symbol: String?
    let currency: String?
    let regularMarketPrice: Double?
    let chartPreviousClose: Double?
    let regularMarketTime: Int?
    let exchangeTimezoneName: String?
    let longName: String?
    let shortName: String?
}

private struct YahooChartIndicators: Decodable {
    let quote: [YahooQuoteIndicator]
    let adjclose: [YahooAdjCloseIndicator]
}

private struct YahooQuoteIndicator: Decodable {
    let open: [Double?]
    let high: [Double?]
    let low: [Double?]
    let close: [Double?]
    let volume: [Double?]
}

private struct YahooAdjCloseIndicator: Decodable {
    let adjclose: [Double?]
}

private struct YahooChartEvents: Decodable {
    let dividends: [String: YahooDividendEvent]?
}

private struct YahooDividendEvent: Decodable {
    let amount: Double
    let date: Int
}
