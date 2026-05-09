import "../cache/local_cache_metadata_status.dart";
import "../domain/market_cache_models.dart";
import "../domain/market_normalization.dart";

enum MarketDataDisplayState { loading, error, noData, ready }

String formatPercent(double value) => "${value >= 0 ? "+" : ""}${value.toStringAsFixed(2)}%";

String formatPrice(double value, String currency) => currency == "USD" ? "\$${value.toStringAsFixed(2)}" : "$currency ${value.toStringAsFixed(2)}";

String normalizedDashboardSymbol(String symbol) {
  try {
    return normalizeSymbol(symbol);
  } catch (_) {
    return symbol;
  }
}

String lastUpdatedText(int? timestampMs) {
  if (timestampMs == null) {
    return "No market data yet";
  }
  final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  return "${dateTime.year}-${dateTime.month.toString().padLeft(2, "0")}-${dateTime.day.toString().padLeft(2, "0")} ${dateTime.hour.toString().padLeft(2, "0")}:${dateTime.minute.toString().padLeft(2, "0")}";
}

MarketDataDisplayState displayState(CachedMarketQuote? quote, bool isLoading) {
  if (quote != null && quote.metadata.derivedStatus(nowMs: DateTime.now().millisecondsSinceEpoch) == CacheStatus.error) {
    return MarketDataDisplayState.error;
  }
  if (quote != null) {
    return MarketDataDisplayState.ready;
  }
  return isLoading ? MarketDataDisplayState.loading : MarketDataDisplayState.noData;
}
