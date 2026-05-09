import Foundation

extension YahooChartParser {
    func buildHistoricalSeries(
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
        let prices = try buildPrices(
            symbol: symbol,
            providerSymbol: providerSymbol,
            currency: currency,
            rawCurrency: rawCurrency,
            timestamps: timestamps,
            quote: quote,
            adjustedClose: adjustedClose
        )

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

    private func buildPrices(
        symbol: String,
        providerSymbol: String?,
        currency: String,
        rawCurrency: String,
        timestamps: [Int],
        quote: YahooQuoteIndicator,
        adjustedClose: [Double?]
    ) throws -> [HistoricalPrice] {
        var prices: [HistoricalPrice] = []
        prices.reserveCapacity(timestamps.count)

        for index in timestamps.indices {
            guard let price = try historicalPrice(
                index: index,
                symbol: symbol,
                providerSymbol: providerSymbol,
                currency: currency,
                rawCurrency: rawCurrency,
                timestamps: timestamps,
                quote: quote,
                adjustedClose: adjustedClose
            ) else {
                continue
            }

            prices.append(price)
        }

        return prices
    }

    private func historicalPrice(
        index: Int,
        symbol: String,
        providerSymbol: String?,
        currency: String,
        rawCurrency: String,
        timestamps: [Int],
        quote: YahooQuoteIndicator,
        adjustedClose: [Double?]
    ) throws -> HistoricalPrice? {
        let timestamp = timestamps[index]
        guard let rawClose = value(at: index, from: quote.close) else {
            return nil
        }

        let close = try normalizePrice(rawClose, currency: currency, rawCurrency: rawCurrency)
        guard close > 0 else {
            return nil
        }

        return HistoricalPrice(
            symbol: symbol,
            providerSymbol: providerSymbol,
            provider: .yahoo,
            currency: currency,
            timestamp: timestamp,
            date: utcDateString(fromUnixSeconds: timestamp),
            open: try normalizeOptionalPrice(value(at: index, from: quote.open), currency: currency, rawCurrency: rawCurrency),
            high: try normalizeOptionalPrice(value(at: index, from: quote.high), currency: currency, rawCurrency: rawCurrency),
            low: try normalizeOptionalPrice(value(at: index, from: quote.low), currency: currency, rawCurrency: rawCurrency),
            close: close,
            adjustedClose: try normalizeOptionalPrice(value(at: index, from: adjustedClose), currency: currency, rawCurrency: rawCurrency),
            volume: normalizedVolume(value(at: index, from: quote.volume))
        )
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
}
