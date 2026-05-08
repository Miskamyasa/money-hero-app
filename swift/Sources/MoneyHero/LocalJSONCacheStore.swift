import Foundation

public enum LocalJSONCacheStoreError: Error, Equatable, Sendable {
    case invalidMetadata
    case invalidPayload
    case kindMismatch
}

public actor LocalJSONCacheStore {
    private let fileManager: FileManager
    private let directoryURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil
    ) throws {
        self.fileManager = fileManager

        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let baseURL = try fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.directoryURL = baseURL.appendingPathComponent("MoneyHeroCache", isDirectory: true)
        }

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        try fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    public func saveMarketQuote(_ envelope: CachedMarketQuote) throws {
        try validateCachedMarketQuote(envelope)
        try write(envelope, key: envelope.metadata.key, kind: .marketQuote)
    }

    public func saveHistoricalPrices(_ envelope: CachedHistoricalPrices) throws {
        try validateCachedHistoricalPrices(envelope)
        try write(envelope, key: envelope.metadata.key, kind: .historicalPrices)
    }

    public func loadMarketQuote(key: String, nowMs: Int) throws -> CachedMarketQuote? {
        guard let envelope: CachedMarketQuote = try read(key: key, kind: .marketQuote) else {
            return nil
        }

        do {
            try validateCachedMarketQuote(envelope)
            return envelope.withDerivedStatus(nowMs: nowMs)
        } catch {
            try remove(key: key, kind: .marketQuote)
            return nil
        }
    }

    public func loadHistoricalPrices(key: String, nowMs: Int) throws -> CachedHistoricalPrices? {
        guard let envelope: CachedHistoricalPrices = try read(key: key, kind: .historicalPrices) else {
            return nil
        }

        do {
            try validateCachedHistoricalPrices(envelope)
            return envelope.withDerivedStatus(nowMs: nowMs)
        } catch {
            try remove(key: key, kind: .historicalPrices)
            return nil
        }
    }

    private func write<T: Encodable>(_ value: T, key: String, kind: CacheKind) throws {
        let data = try encoder.encode(value)
        let url = fileURL(for: key, kind: kind)
        try data.write(to: url, options: .atomic)
    }

    private func read<T: Decodable>(key: String, kind: CacheKind) throws -> T? {
        let url = fileURL(for: key, kind: kind)

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private func remove(key: String, kind: CacheKind) throws {
        let url = fileURL(for: key, kind: kind)
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try fileManager.removeItem(at: url)
    }

    private func fileURL(for key: String, kind: CacheKind) -> URL {
        directoryURL.appendingPathComponent(fileName(for: key, kind: kind), isDirectory: false)
    }

    private func fileName(for key: String, kind: CacheKind) -> String {
        let sanitizedKey = key.unicodeScalars.map { scalar in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_" {
                return String(scalar)
            }
            return "_"
        }.joined()

        return "\(kind.rawValue)_\(sanitizedKey).json"
    }
}

public extension LocalCacheMetadata {
    func derivedStatus(nowMs: Int) -> CacheStatus {
        if error != nil {
            return .error
        }

        if nowMs >= expiresAt {
            return .expired
        }

        if nowMs >= staleAt {
            return .stale
        }

        return .fresh
    }

    var lastUpdatedAtMs: Int {
        fetchedAt
    }
}

private func validateCachedMarketQuote(_ envelope: CachedMarketQuote) throws {
    try validateMetadata(envelope.metadata, expectedKind: .marketQuote)
    try validateQuote(envelope.data)
}

private func validateCachedHistoricalPrices(_ envelope: CachedHistoricalPrices) throws {
    try validateMetadata(envelope.metadata, expectedKind: .historicalPrices)
    try validateHistoricalSeries(envelope.data)
}

private func validateMetadata(_ metadata: LocalCacheMetadata, expectedKind: CacheKind) throws {
    guard metadata.kind == expectedKind else {
        throw LocalJSONCacheStoreError.kindMismatch
    }

    guard !metadata.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          metadata.schemaVersion > 0,
          metadata.fetchedAt >= 0,
          metadata.staleAt >= 0,
          metadata.expiresAt >= 0,
          metadata.writtenAt >= 0,
          metadata.staleAt <= metadata.expiresAt else {
        throw LocalJSONCacheStoreError.invalidMetadata
    }
}

private func validateQuote(_ quote: MarketQuote) throws {
    _ = try normalizeSymbol(quote.symbol)
    _ = try normalizeCurrencyCode(quote.currency)

    try validateFiniteNumber(quote.price, field: "price")
    try validateFiniteNumber(quote.previousClose, field: "previousClose")
    try validateFiniteNumber(quote.change, field: "change")
    try validateFiniteNumber(quote.changePercent, field: "changePercent")

    guard quote.price > 0,
          quote.previousClose >= 0,
          !quote.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw LocalJSONCacheStoreError.invalidPayload
    }

    for dividend in quote.dividends {
        try validateFiniteNumber(dividend.amount, field: "dividend.amount")
    }

    try validateOptionalFinite(quote.change1m, field: "change1m")
    try validateOptionalFinite(quote.change6m, field: "change6m")
    try validateOptionalFinite(quote.change1y, field: "change1y")
    try validateOptionalFinite(quote.change2y, field: "change2y")
}

private func validateHistoricalSeries(_ series: HistoricalPriceSeries) throws {
    _ = try normalizeSymbol(series.symbol)
    _ = try normalizeCurrencyCode(series.currency)

    guard !series.prices.isEmpty else {
        throw LocalJSONCacheStoreError.invalidPayload
    }

    for price in series.prices {
        _ = try normalizeSymbol(price.symbol)
        _ = try normalizeCurrencyCode(price.currency)
        try validateFiniteNumber(price.close, field: "close")
        guard price.close > 0 else {
            throw LocalJSONCacheStoreError.invalidPayload
        }
        try validateOptionalFinite(price.open, field: "open")
        try validateOptionalFinite(price.high, field: "high")
        try validateOptionalFinite(price.low, field: "low")
        try validateOptionalFinite(price.adjustedClose, field: "adjustedClose")
    }
}

private func validateOptionalFinite(_ value: Double?, field: String) throws {
    guard let value else {
        return
    }
    try validateFiniteNumber(value, field: field)
}

private extension CachedMarketQuote {
    func withDerivedStatus(nowMs: Int) -> CachedMarketQuote {
        let status = metadata.derivedStatus(nowMs: nowMs)
        let derivedMetadata = LocalCacheMetadata(
            key: metadata.key,
            kind: metadata.kind,
            provider: metadata.provider,
            symbol: metadata.symbol,
            fetchedAt: metadata.fetchedAt,
            staleAt: metadata.staleAt,
            expiresAt: metadata.expiresAt,
            writtenAt: metadata.writtenAt,
            status: status,
            source: .cache,
            schemaVersion: metadata.schemaVersion,
            etag: metadata.etag,
            error: metadata.error
        )
        return CachedMarketQuote(metadata: derivedMetadata, data: data)
    }
}

private extension CachedHistoricalPrices {
    func withDerivedStatus(nowMs: Int) -> CachedHistoricalPrices {
        let status = metadata.derivedStatus(nowMs: nowMs)
        let derivedMetadata = LocalCacheMetadata(
            key: metadata.key,
            kind: metadata.kind,
            provider: metadata.provider,
            symbol: metadata.symbol,
            fetchedAt: metadata.fetchedAt,
            staleAt: metadata.staleAt,
            expiresAt: metadata.expiresAt,
            writtenAt: metadata.writtenAt,
            status: status,
            source: .cache,
            schemaVersion: metadata.schemaVersion,
            etag: metadata.etag,
            error: metadata.error
        )
        return CachedHistoricalPrices(metadata: derivedMetadata, data: data)
    }
}
