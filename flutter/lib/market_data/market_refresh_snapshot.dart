import "../domain/market_cache_models.dart";
import "market_fetch_queue.dart";

class MarketRefreshSnapshot {
  const MarketRefreshSnapshot({
    required this.quotesBySymbol,
    required this.historiesBySymbol,
    required this.progress,
    required this.lastUpdatedAtMs,
    required this.refreshErrorMessage,
  });

  final Map<String, CachedMarketQuote> quotesBySymbol;
  final Map<String, CachedHistoricalPrices> historiesBySymbol;
  final MarketFetchQueueProgress progress;
  final int? lastUpdatedAtMs;
  final String? refreshErrorMessage;

  static const MarketRefreshSnapshot empty = MarketRefreshSnapshot(
    quotesBySymbol: <String, CachedMarketQuote>{},
    historiesBySymbol: <String, CachedHistoricalPrices>{},
    progress: MarketFetchQueueProgress(totalCount: 0, completedCount: 0, running: false, currentLabel: null),
    lastUpdatedAtMs: null,
    refreshErrorMessage: null,
  );
}
