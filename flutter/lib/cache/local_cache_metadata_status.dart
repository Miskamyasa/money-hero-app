import "../domain/market_cache_models.dart";

extension LocalCacheMetadataStatus on LocalCacheMetadata {
  CacheStatus derivedStatus({required int nowMs}) {
    if (error != null) {
      return CacheStatus.error;
    }
    if (nowMs >= expiresAt) {
      return CacheStatus.expired;
    }
    if (nowMs >= staleAt) {
      return CacheStatus.stale;
    }
    return CacheStatus.fresh;
  }

  int get lastUpdatedAtMs => fetchedAt;

  LocalCacheMetadata withDerivedStatus({required int nowMs}) {
    return copyWith(status: derivedStatus(nowMs: nowMs), source: CacheSource.cache);
  }
}

extension CachedMarketQuoteStatus on CachedMarketQuote {
  CachedMarketQuote withDerivedStatus({required int nowMs}) {
    return CachedMarketQuote(metadata: metadata.withDerivedStatus(nowMs: nowMs), data: data);
  }
}

extension CachedHistoricalPricesStatus on CachedHistoricalPrices {
  CachedHistoricalPrices withDerivedStatus({required int nowMs}) {
    return CachedHistoricalPrices(metadata: metadata.withDerivedStatus(nowMs: nowMs), data: data);
  }
}
