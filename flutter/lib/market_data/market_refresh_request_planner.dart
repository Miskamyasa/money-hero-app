import "../domain/holdings_models.dart";
import "../domain/market_normalization.dart";

enum MarketRefreshTrackedSymbolKind { market, currency }

class MarketRefreshTrackedSymbolRequest {
  const MarketRefreshTrackedSymbolRequest({required this.symbol, required this.kind});

  final String symbol;
  final MarketRefreshTrackedSymbolKind kind;
}

class MarketRefreshRequestPlanner {
  static List<String> trackedSymbols({
    required List<DashboardWidget> activeWidgets,
    required List<Holding> holdings,
    required CurrencyWidgetSetting currencySettings,
    required MarketTickerSetting marketTickerSettings,
  }) {
    return trackedRequests(
      activeWidgets: activeWidgets,
      holdings: holdings,
      currencySettings: currencySettings,
      marketTickerSettings: marketTickerSettings,
    ).map((MarketRefreshTrackedSymbolRequest e) => e.symbol).toList();
  }

  static List<MarketRefreshTrackedSymbolRequest> trackedRequests({
    required List<DashboardWidget> activeWidgets,
    required List<Holding> holdings,
    required CurrencyWidgetSetting currencySettings,
    required MarketTickerSetting marketTickerSettings,
  }) {
    final List<MarketRefreshTrackedSymbolRequest> requests = <MarketRefreshTrackedSymbolRequest>[];
    if (activeWidgets.contains(DashboardWidget.keyMarkets)) {
      for (final String symbol in marketTickerSettings.symbols) {
        try {
          requests.add(MarketRefreshTrackedSymbolRequest(symbol: normalizeSymbol(symbol), kind: MarketRefreshTrackedSymbolKind.market));
        } catch (_) {}
      }
    }
    if (activeWidgets.contains(DashboardWidget.currencies)) {
      for (final String symbol in currencySettings.symbols) {
        try {
          requests.add(MarketRefreshTrackedSymbolRequest(symbol: normalizeCurrencyCode(symbol), kind: MarketRefreshTrackedSymbolKind.currency));
        } catch (_) {}
      }
    }
    for (final Holding holding in holdings) {
      if (holding.isHidden) {
        continue;
      }
      try {
        requests.add(MarketRefreshTrackedSymbolRequest(symbol: normalizeSymbol(holding.symbol), kind: MarketRefreshTrackedSymbolKind.market));
      } catch (_) {}
    }
    final Set<String> seen = <String>{};
    return requests.where((MarketRefreshTrackedSymbolRequest request) => seen.add(request.symbol)).toList();
  }
}
