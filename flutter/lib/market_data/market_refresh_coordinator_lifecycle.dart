part of "market_refresh_coordinator.dart";

Future<void> _refreshCoordinator(MarketRefreshCoordinator coordinator, {required List<Holding> holdings, required List<WidgetSetting> widgetSettings, required CurrencyWidgetSetting currencySettings, required MarketTickerSetting marketTickerSettings}) async {
  if (coordinator._refreshIsActive) {
    return;
  }
  coordinator._refreshIsActive = true;
  coordinator._refreshErrorMessage = null;
  coordinator._progress = coordinator._fetchQueue.clearPending(resetCompletedCount: true);

  final List<DashboardWidget> activeWidgets = _activeWidgets(widgetSettings);
  final List<MarketRefreshTrackedSymbolRequest> requests = MarketRefreshRequestPlanner.trackedRequests(activeWidgets: activeWidgets, holdings: holdings, currencySettings: currencySettings, marketTickerSettings: marketTickerSettings);
  final Set<String> symbols = requests.map((MarketRefreshTrackedSymbolRequest e) => e.symbol).toSet();
  _pruneActiveSnapshots(coordinator, symbols);

  await _hydrateCache(coordinator, symbols);
  coordinator._emitSnapshot();
  if (requests.isEmpty) {
    coordinator._refreshIsActive = false;
    return;
  }

  for (final MarketRefreshTrackedSymbolRequest request in requests) {
    coordinator._fetchQueue.enqueue(MarketFetchQueueTask(cacheKey: "quote:${request.symbol}", label: "Quote ${request.symbol}", operation: () => _runFetch(coordinator, request)));
  }
  while (coordinator._fetchQueue.progress.isActive) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  coordinator._refreshIsActive = false;
}

List<DashboardWidget> _activeWidgets(List<WidgetSetting> widgetSettings) {
  return (widgetSettings.where((WidgetSetting item) => !item.isHidden).toList()..sort((WidgetSetting a, WidgetSetting b) => a.order.compareTo(b.order))).map((WidgetSetting e) => e.widget).toList();
}

void _pruneActiveSnapshots(MarketRefreshCoordinator coordinator, Set<String> symbols) {
  coordinator._quotesBySymbol.removeWhere((String key, _) => !symbols.contains(key));
  coordinator._historiesBySymbol.removeWhere((String key, _) => !symbols.contains(key));
}
