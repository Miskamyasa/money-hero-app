part of "../money_hero_test.dart";

void registerQueueAndRefreshTests() {
  test("queue cache-key dedupe", () async {
    final MarketFetchQueue queue = MarketFetchQueue();
    int hits = 0;
    queue.enqueue(MarketFetchQueueTask(cacheKey: "quote:AAPL", label: "1", operation: () async => hits += 1));
    queue.enqueue(MarketFetchQueueTask(cacheKey: " quote:AAPL ", label: "2", operation: () async => hits += 1));
    queue.enqueue(MarketFetchQueueTask(cacheKey: "history:AAPL", label: "3", operation: () async => hits += 1));
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    expect(hits, 2);
  });

  test("hydrated snapshot emits before progress and failure keeps cached", () async {
    final _MemoryCacheStore cache = _MemoryCacheStore();
    await cache.saveMarketQuote(cachedQuote("AAPL", 100));
    final MarketRefreshCoordinator coordinator = MarketRefreshCoordinator(cacheStore: cache, yahooClient: _StubProvider(shouldFail: true), parser: _StubParser());
    final List<int> cachedIndexes = <int>[];
    final List<int> activeIndexes = <int>[];
    int index = 0;
    final sub = coordinator.snapshots().listen((s) {
      if (s.quotesBySymbol["AAPL"]?.metadata.source == CacheSource.cache && !s.progress.isActive) {
        cachedIndexes.add(index);
      }
      if (s.progress.isActive) {
        activeIndexes.add(index);
      }
      index += 1;
    });
    await coordinator.refreshOnPullToRefresh(holdings: const <Holding>[], widgetSettings: const <WidgetSetting>[WidgetSetting(widget: DashboardWidget.keyMarkets, isHidden: false, order: 0)], currencySettings: const CurrencyWidgetSetting(symbols: <String>[]), marketTickerSettings: const MarketTickerSetting(symbols: <String>["AAPL"]));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel();
    expect(cachedIndexes.isNotEmpty, true);
    expect(activeIndexes.isNotEmpty, true);
    expect(cachedIndexes.first < activeIndexes.first, true);
    expect(coordinator.snapshot().quotesBySymbol["AAPL"]?.metadata.status, CacheStatus.error);
  });

  test("dashboard loading and refreshing transitions", () async {
    final DashboardState state = DashboardState(coordinator: MarketRefreshCoordinator(cacheStore: _MemoryCacheStore(), yahooClient: _StubProvider(), parser: _StubParser()), currencySettings: const CurrencyWidgetSetting(symbols: <String>[]), marketTickerSettings: const MarketTickerSetting(symbols: <String>["AAPL"]));
    final Future<void> task = state.refreshOnAppOpen();
    await Future<void>.delayed(Duration.zero);
    expect(state.isRefreshing, true);
    await task;
    expect(state.isInitialLoading, false);
  });
}
