import Foundation

typealias YahooQuoteMetrics = (
    previousClose: Double,
    change: Double,
    changePercent: Double,
    change1m: Double?,
    change6m: Double?,
    change1y: Double?,
    change2y: Double?
)

extension YahooChartParser {
    func deriveQuoteMetrics(series: HistoricalPriceSeries, currentPrice: Double) throws -> YahooQuoteMetrics {
        let closes = series.prices.map(\.close)
        guard let latestClose = closes.last else {
            throw YahooChartParserError.invalidPriceSeries
        }

        let previousClose = closes.dropLast().last ?? latestClose
        let change = currentPrice - previousClose
        let changePercent = previousClose == 0 ? 0 : (change / previousClose) * 100

        return (
            previousClose,
            change,
            changePercent,
            anchorPercentChange(series: series, monthsAgo: 1, currentPrice: currentPrice),
            anchorPercentChange(series: series, monthsAgo: 6, currentPrice: currentPrice),
            anchorPercentChange(series: series, yearsAgo: 1, currentPrice: currentPrice),
            anchorPercentChange(series: series, yearsAgo: 2, currentPrice: currentPrice)
        )
    }

    func parseDividends(rawDividends: [String: YahooDividendEvent]?, rawCurrency: String) throws -> [DividendEvent] {
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

    private func anchorPercentChange(
        series: HistoricalPriceSeries,
        monthsAgo: Int? = nil,
        yearsAgo: Int? = nil,
        currentPrice: Double
    ) -> Double? {
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
}
