part of "market_refresh_coordinator.dart";

Future<void> _hydrateCache(MarketRefreshCoordinator coordinator, Set<String> symbols) async {
  int? latest;
  for (final String symbol in symbols) {
    final int nowMs = coordinator._clock.nowMilliseconds();
    final CachedMarketQuote? quote = await coordinator.cacheStore.loadMarketQuote(key: "quote:$symbol", nowMs: nowMs);
    if (quote != null) {
      coordinator._quotesBySymbol[symbol] = quote;
      latest = _latestUpdatedAt(latest, quote.metadata.lastUpdatedAtMs);
    }
    final CachedHistoricalPrices? history = await coordinator.cacheStore.loadHistoricalPrices(key: "history:$symbol", nowMs: nowMs);
    if (history != null) {
      coordinator._historiesBySymbol[symbol] = history;
      latest = _latestUpdatedAt(latest, history.metadata.lastUpdatedAtMs);
    }
  }
  coordinator._lastUpdatedAtMs = latest;
}

int _latestUpdatedAt(int? current, int candidate) {
  if (current == null) {
    return candidate;
  }
  return current > candidate ? current : candidate;
}

LocalCacheMetadata _quoteMetadata(String symbol, int nowMs) {
  return LocalCacheMetadata(key: "quote:$symbol", kind: CacheKind.marketQuote, provider: MarketDataProvider.yahoo, symbol: symbol, fetchedAt: nowMs, staleAt: nowMs + (20 * 60 * 1000), expiresAt: nowMs + (24 * 60 * 60 * 1000), writtenAt: nowMs, status: CacheStatus.fresh, source: CacheSource.network, schemaVersion: 1, etag: null, error: null);
}

LocalCacheMetadata _historyMetadata(String symbol, int nowMs) {
  return LocalCacheMetadata(key: "history:$symbol", kind: CacheKind.historicalPrices, provider: MarketDataProvider.yahoo, symbol: symbol, fetchedAt: nowMs, staleAt: nowMs + (24 * 60 * 60 * 1000), expiresAt: nowMs + (7 * 24 * 60 * 60 * 1000), writtenAt: nowMs, status: CacheStatus.fresh, source: CacheSource.network, schemaVersion: 1, etag: null, error: null);
}
