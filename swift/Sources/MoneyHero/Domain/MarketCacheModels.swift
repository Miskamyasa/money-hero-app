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
