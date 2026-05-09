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

extension CachedMarketQuote {
    func withDerivedStatus(nowMs: Int) -> CachedMarketQuote {
        CachedMarketQuote(metadata: metadata.withDerivedStatus(nowMs: nowMs), data: data)
    }
}

extension CachedHistoricalPrices {
    func withDerivedStatus(nowMs: Int) -> CachedHistoricalPrices {
        CachedHistoricalPrices(metadata: metadata.withDerivedStatus(nowMs: nowMs), data: data)
    }
}

private extension LocalCacheMetadata {
    func withDerivedStatus(nowMs: Int) -> LocalCacheMetadata {
        LocalCacheMetadata(
            key: key,
            kind: kind,
            provider: provider,
            symbol: symbol,
            fetchedAt: fetchedAt,
            staleAt: staleAt,
            expiresAt: expiresAt,
            writtenAt: writtenAt,
            status: derivedStatus(nowMs: nowMs),
            source: .cache,
            schemaVersion: schemaVersion,
            etag: etag,
            error: error
        )
    }
}
