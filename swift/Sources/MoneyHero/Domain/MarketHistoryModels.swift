public enum HistoricalPriceInterval: String, Codable, Equatable, Sendable {
    case oneDay = "1d"
}

public enum HistoricalPriceRange: String, Codable, Equatable, Sendable {
    case oneMonth = "1mo"
    case sixMonths = "6mo"
    case oneYear = "1y"
    case twoYears = "2y"
    case custom
}

public struct HistoricalPrice: Codable, Equatable, Sendable {
    public let symbol: String
    public let providerSymbol: String?
    public let provider: MarketDataProvider
    public let currency: String
    public let timestamp: Int
    public let date: String
    public let open: Double?
    public let high: Double?
    public let low: Double?
    public let close: Double
    public let adjustedClose: Double?
    public let volume: Int?

    public init(
        symbol: String,
        providerSymbol: String?,
        provider: MarketDataProvider,
        currency: String,
        timestamp: Int,
        date: String,
        open: Double?,
        high: Double?,
        low: Double?,
        close: Double,
        adjustedClose: Double?,
        volume: Int?
    ) {
        self.symbol = symbol
        self.providerSymbol = providerSymbol
        self.provider = provider
        self.currency = currency
        self.timestamp = timestamp
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.adjustedClose = adjustedClose
        self.volume = volume
    }
}

public struct HistoricalPriceSeries: Codable, Equatable, Sendable {
    public let symbol: String
    public let providerSymbol: String?
    public let provider: MarketDataProvider
    public let currency: String
    public let interval: HistoricalPriceInterval
    public let range: HistoricalPriceRange
    public let prices: [HistoricalPrice]

    public init(
        symbol: String,
        providerSymbol: String?,
        provider: MarketDataProvider,
        currency: String,
        interval: HistoricalPriceInterval,
        range: HistoricalPriceRange,
        prices: [HistoricalPrice]
    ) {
        self.symbol = symbol
        self.providerSymbol = providerSymbol
        self.provider = provider
        self.currency = currency
        self.interval = interval
        self.range = range
        self.prices = prices
    }
}
