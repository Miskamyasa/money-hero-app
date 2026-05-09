struct YahooChartPayload: Decodable {
    let chart: YahooChartContainer
}

struct YahooChartContainer: Decodable {
    let result: [YahooChartResult]?
}

struct YahooChartResult: Decodable {
    let meta: YahooChartMeta
    let timestamp: [Int]?
    let indicators: YahooChartIndicators
    let events: YahooChartEvents?
}

struct YahooChartMeta: Decodable {
    let symbol: String?
    let currency: String?
    let regularMarketPrice: Double?
    let chartPreviousClose: Double?
    let regularMarketTime: Int?
    let exchangeTimezoneName: String?
    let longName: String?
    let shortName: String?
}

struct YahooChartIndicators: Decodable {
    let quote: [YahooQuoteIndicator]
    let adjclose: [YahooAdjCloseIndicator]
}

struct YahooQuoteIndicator: Decodable {
    let open: [Double?]
    let high: [Double?]
    let low: [Double?]
    let close: [Double?]
    let volume: [Double?]
}

struct YahooAdjCloseIndicator: Decodable {
    let adjclose: [Double?]
}

struct YahooChartEvents: Decodable {
    let dividends: [String: YahooDividendEvent]?
}

struct YahooDividendEvent: Decodable {
    let amount: Double
    let date: Int
}
