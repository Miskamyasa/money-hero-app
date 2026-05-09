part of "market_refresh_coordinator.dart";

Future<void> _runFetch(MarketRefreshCoordinator coordinator, MarketRefreshTrackedSymbolRequest request) async {
  final int nowMs = coordinator._clock.nowMilliseconds();
  try {
    final MarketQuoteFetchResult result = await coordinator._quoteFetcher.fetch(symbol: request.symbol, kind: request.kind);
    await _persistSuccess(coordinator, result, nowMs);
  } catch (error) {
    _applyFailure(coordinator, request.symbol, error.toString());
  }
  coordinator._emitSnapshot();
}

Future<void> _persistSuccess(MarketRefreshCoordinator coordinator, MarketQuoteFetchResult result, int nowMs) async {
  final CachedMarketQuote quoteEnvelope = CachedMarketQuote(metadata: _quoteMetadata(result.symbol, nowMs), data: result.quote);
  await coordinator.cacheStore.saveMarketQuote(quoteEnvelope);
  coordinator._quotesBySymbol[result.symbol] = quoteEnvelope.withDerivedStatus(nowMs: nowMs);
  coordinator._lastUpdatedAtMs = nowMs;

  if (result.history == null) {
    return;
  }
  final CachedHistoricalPrices historyEnvelope = CachedHistoricalPrices(metadata: _historyMetadata(result.symbol, nowMs), data: result.history!);
  await coordinator.cacheStore.saveHistoricalPrices(historyEnvelope);
  coordinator._historiesBySymbol[result.symbol] = historyEnvelope.withDerivedStatus(nowMs: nowMs);
}

void _applyFailure(MarketRefreshCoordinator coordinator, String symbol, String errorMessage) {
  final CachedMarketQuote? cached = coordinator._quotesBySymbol[symbol];
  if (cached == null) {
    coordinator._refreshErrorMessage = errorMessage;
    return;
  }
  coordinator._quotesBySymbol[symbol] = CachedMarketQuote(
    metadata: cached.metadata.copyWith(status: CacheStatus.error, source: CacheSource.cache, error: errorMessage),
    data: cached.data,
  );
}
