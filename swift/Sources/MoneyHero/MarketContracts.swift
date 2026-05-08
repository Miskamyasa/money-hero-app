public enum MarketDataProvider: String, Codable, Equatable, Sendable {
    case yahoo
}

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

public enum CacheKind: String, Codable, Equatable, Sendable {
    case marketQuote = "market-quote"
    case historicalPrices = "historical-prices"
    case currencyRates = "currency-rates"
    case goldQuote = "gold-quote"
    case goldHistory = "gold-history"
    case symbolWidget = "symbol-widget"
}

public enum CacheStatus: String, Codable, Equatable, Sendable {
    case fresh
    case stale
    case expired
    case error
}

public enum CacheSource: String, Codable, Equatable, Sendable {
    case network
    case cache
}

public struct DividendEvent: Codable, Equatable, Sendable {
    public let amount: Double
    public let date: Int

    public init(amount: Double, date: Int) {
        self.amount = amount
        self.date = date
    }
}

public struct MarketQuote: Codable, Equatable, Sendable {
    public let symbol: String
    public let providerSymbol: String?
    public let name: String
    public let provider: MarketDataProvider
    public let price: Double
    public let previousClose: Double
    public let change: Double
    public let changePercent: Double
    public let currency: String
    public let marketTime: Int?
    public let exchangeTimezoneName: String?
    public let change1m: Double?
    public let change6m: Double?
    public let change1y: Double?
    public let change2y: Double?
    public let dividends: [DividendEvent]

    public init(
        symbol: String,
        providerSymbol: String?,
        name: String,
        provider: MarketDataProvider,
        price: Double,
        previousClose: Double,
        change: Double,
        changePercent: Double,
        currency: String,
        marketTime: Int?,
        exchangeTimezoneName: String?,
        change1m: Double?,
        change6m: Double?,
        change1y: Double?,
        change2y: Double?,
        dividends: [DividendEvent]
    ) {
        self.symbol = symbol
        self.providerSymbol = providerSymbol
        self.name = name
        self.provider = provider
        self.price = price
        self.previousClose = previousClose
        self.change = change
        self.changePercent = changePercent
        self.currency = currency
        self.marketTime = marketTime
        self.exchangeTimezoneName = exchangeTimezoneName
        self.change1m = change1m
        self.change6m = change6m
        self.change1y = change1y
        self.change2y = change2y
        self.dividends = dividends
    }
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

public struct LocalCacheMetadata: Codable, Equatable, Sendable {
    public let key: String
    public let kind: CacheKind
    public let provider: MarketDataProvider
    public let symbol: String?
    public let fetchedAt: Int
    public let staleAt: Int
    public let expiresAt: Int
    public let writtenAt: Int
    public let status: CacheStatus
    public let source: CacheSource
    public let schemaVersion: Int
    public let etag: String?
    public let error: String?

    public init(
        key: String,
        kind: CacheKind,
        provider: MarketDataProvider,
        symbol: String?,
        fetchedAt: Int,
        staleAt: Int,
        expiresAt: Int,
        writtenAt: Int,
        status: CacheStatus,
        source: CacheSource,
        schemaVersion: Int,
        etag: String?,
        error: String?
    ) {
        self.key = key
        self.kind = kind
        self.provider = provider
        self.symbol = symbol
        self.fetchedAt = fetchedAt
        self.staleAt = staleAt
        self.expiresAt = expiresAt
        self.writtenAt = writtenAt
        self.status = status
        self.source = source
        self.schemaVersion = schemaVersion
        self.etag = etag
        self.error = error
    }
}

public struct CachedMarketQuote: Codable, Equatable, Sendable {
    public let metadata: LocalCacheMetadata
    public let data: MarketQuote

    public init(metadata: LocalCacheMetadata, data: MarketQuote) {
        self.metadata = metadata
        self.data = data
    }
}

public struct CachedHistoricalPrices: Codable, Equatable, Sendable {
    public let metadata: LocalCacheMetadata
    public let data: HistoricalPriceSeries

    public init(metadata: LocalCacheMetadata, data: HistoricalPriceSeries) {
        self.metadata = metadata
        self.data = data
    }
}
