import "dart:async";

import "../cache/local_cache_metadata_status.dart";
import "../domain/holdings_models.dart";
import "../domain/market_cache_models.dart";
import "../domain/market_provider_models.dart";
import "market_data_protocols.dart";
import "market_fetch_queue.dart";
import "market_quote_fetcher.dart";
import "market_refresh_request_planner.dart";
import "market_refresh_snapshot.dart";
import "yahoo_chart_parser.dart";
import "yahoo_finance_client.dart";

part "market_refresh_coordinator_cache.dart";
part "market_refresh_coordinator_fetch.dart";
part "market_refresh_coordinator_lifecycle.dart";

class MarketRefreshCoordinator {
  MarketRefreshCoordinator({
    required this.cacheStore,
    MarketDataProviding? yahooClient,
    MarketChartParser? parser,
    MarketFetchQueue? fetchQueue,
    ClockProvider? clock,
  })  : _provider = yahooClient ?? YahooFinanceClient(),
        _parser = parser ?? YahooChartParser(),
        _fetchQueue = fetchQueue ?? MarketFetchQueue(),
        _clock = clock ?? const SystemClockProvider(),
        _streamController = StreamController<MarketRefreshSnapshot>.broadcast() {
    _quoteFetcher = MarketQuoteFetcher(provider: _provider, parser: _parser);
    _fetchQueue.progressStream().listen((MarketFetchQueueProgress progress) {
      _progress = progress;
      _emitSnapshot();
    });
  }

  final MarketCacheStore cacheStore;
  final MarketDataProviding _provider;
  final MarketChartParser _parser;
  final MarketFetchQueue _fetchQueue;
  final ClockProvider _clock;
  final StreamController<MarketRefreshSnapshot> _streamController;
  late final MarketQuoteFetcher _quoteFetcher;

  final Map<String, CachedMarketQuote> _quotesBySymbol = <String, CachedMarketQuote>{};
  final Map<String, CachedHistoricalPrices> _historiesBySymbol = <String, CachedHistoricalPrices>{};
  MarketFetchQueueProgress _progress = const MarketFetchQueueProgress(totalCount: 0, completedCount: 0, running: false, currentLabel: null);
  int? _lastUpdatedAtMs;
  String? _refreshErrorMessage;
  bool _refreshIsActive = false;

  Stream<MarketRefreshSnapshot> snapshots() {
    _emitSnapshot();
    return _streamController.stream;
  }

  Future<void> refreshOnAppOpen({
    required List<Holding> holdings,
    List<WidgetSetting> widgetSettings = WidgetDefaults.mvp,
    CurrencyWidgetSetting currencySettings = CurrencyWidgetSetting.defaults,
    MarketTickerSetting marketTickerSettings = MarketTickerSetting.defaults,
  }) {
    return _refresh(holdings: holdings, widgetSettings: widgetSettings, currencySettings: currencySettings, marketTickerSettings: marketTickerSettings);
  }

  Future<void> refreshOnPullToRefresh({
    required List<Holding> holdings,
    List<WidgetSetting> widgetSettings = WidgetDefaults.mvp,
    CurrencyWidgetSetting currencySettings = CurrencyWidgetSetting.defaults,
    MarketTickerSetting marketTickerSettings = MarketTickerSetting.defaults,
  }) {
    return _refresh(holdings: holdings, widgetSettings: widgetSettings, currencySettings: currencySettings, marketTickerSettings: marketTickerSettings);
  }

  MarketRefreshSnapshot snapshot() => MarketRefreshSnapshot(
        quotesBySymbol: Map<String, CachedMarketQuote>.from(_quotesBySymbol),
        historiesBySymbol: Map<String, CachedHistoricalPrices>.from(_historiesBySymbol),
        progress: _progress,
        lastUpdatedAtMs: _lastUpdatedAtMs,
        refreshErrorMessage: _refreshErrorMessage,
      );

  static List<String> trackedSymbols({
    required List<DashboardWidget> activeWidgets,
    required List<Holding> holdings,
    required CurrencyWidgetSetting currencySettings,
    required MarketTickerSetting marketTickerSettings,
  }) {
    return MarketRefreshRequestPlanner.trackedSymbols(
      activeWidgets: activeWidgets,
      holdings: holdings,
      currencySettings: currencySettings,
      marketTickerSettings: marketTickerSettings,
    );
  }

  Future<void> _refresh({required List<Holding> holdings, required List<WidgetSetting> widgetSettings, required CurrencyWidgetSetting currencySettings, required MarketTickerSetting marketTickerSettings}) {
    return _refreshCoordinator(this, holdings: holdings, widgetSettings: widgetSettings, currencySettings: currencySettings, marketTickerSettings: marketTickerSettings);
  }

  void _emitSnapshot() {
    if (!_streamController.isClosed) {
      _streamController.add(snapshot());
    }
  }
}
