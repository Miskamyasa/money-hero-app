import Foundation

public enum LocalJSONCacheStoreError: Error, Equatable, Sendable {
    case invalidMetadata
    case invalidPayload
    case kindMismatch
}

public actor LocalJSONCacheStore: MarketCacheStoring {
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

    public func saveMarketQuote(_ envelope: CachedMarketQuote) async throws {
        try validateCachedMarketQuote(envelope)
        try write(envelope, key: envelope.metadata.key, kind: .marketQuote)
    }

    public func saveHistoricalPrices(_ envelope: CachedHistoricalPrices) async throws {
        try validateCachedHistoricalPrices(envelope)
        try write(envelope, key: envelope.metadata.key, kind: .historicalPrices)
    }

    public func loadMarketQuote(key: String, nowMs: Int) async throws -> CachedMarketQuote? {
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

    public func loadHistoricalPrices(key: String, nowMs: Int) async throws -> CachedHistoricalPrices? {
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
