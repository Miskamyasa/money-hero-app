import Testing
@testable import MoneyHero

@Test func trackedSymbolsUseConfigurableMarketsAndDeduplicateHiddenHoldings() {
    let symbols = MarketRefreshCoordinator.trackedSymbols(
        activeWidgets: [.currencies, .keyMarkets],
        holdings: [
            Holding(symbol: " aapl ", shares: 1, targetWeight: nil, isHidden: false),
            Holding(symbol: "AAPL", shares: 2, targetWeight: nil, isHidden: false),
            Holding(symbol: "MSFT", shares: 3, targetWeight: nil, isHidden: true)
        ],
        currencySettings: CurrencyWidgetSetting(symbols: ["USD", "EUR", "GBP"]),
        marketTickerSettings: MarketTickerSetting(symbols: [" GC=F ", "^GSPC"])
    )

    #expect(symbols == [
        "GC=F",
        "^GSPC",
        "USD",
        "EUR",
        "GBP",
        "AAPL"
    ])
}

@Test func coordinatorEmitsHydratedSnapshotBeforeNetworkProgress() async throws {
    let cacheStore = MemoryCacheStore(quotes: ["AAPL": makeCachedQuote(symbol: "AAPL", fetchedAt: 1_000)])
    let coordinator = MarketRefreshCoordinator(
        cacheStore: cacheStore,
        yahooClient: StubMarketDataProvider(delay: .milliseconds(80)),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 2_000)
    )
    let collector = SnapshotCollector()
    let collectTask = Task {
        for await snapshot in coordinator.snapshots() {
            await collector.append(snapshot)
        }
    }

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )
    try await Task.sleep(for: .milliseconds(160))
    collectTask.cancel()

    let snapshots = await collector.values
    let hydratedIndex = snapshots.firstIndex { $0.quotesBySymbol["AAPL"]?.metadata.source == .cache && !$0.progress.isActive }
    let activeIndex = snapshots.firstIndex { $0.progress.isActive }

    #expect(hydratedIndex != nil)
    #expect(activeIndex != nil)
    if let hydratedIndex, let activeIndex {
        #expect(hydratedIndex < activeIndex)
    }
}

@Test func coordinatorEmitsProgressAndResetsBetweenRuns() async throws {
    let coordinator = MarketRefreshCoordinator(
        cacheStore: MemoryCacheStore(),
        yahooClient: StubMarketDataProvider(delay: .milliseconds(20)),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 4_000)
    )
    let collector = SnapshotCollector()
    let collectTask = Task {
        for await snapshot in coordinator.snapshots() {
            await collector.append(snapshot)
        }
    }

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )
    try await Task.sleep(for: .milliseconds(120))

    let firstRunSnapshots = await collector.values
    #expect(firstRunSnapshots.contains { $0.progress.isActive })
    #expect(firstRunSnapshots.contains { $0.progress.totalCount == 1 && $0.progress.completedCount == 1 && !$0.progress.isActive })

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["MSFT"])
    )
    try await Task.sleep(for: .milliseconds(1_200))
    collectTask.cancel()

    let latest = await collector.values.last
    #expect(latest?.progress.totalCount == 1)
    #expect(latest?.progress.completedCount == 1)
}

@Test func coordinatorIgnoresOverlappingRefreshForSameRunningSymbol() async throws {
    let gate = FirstFetchGate()
    let provider = GatedMarketDataProvider(gate: gate)
    let coordinator = MarketRefreshCoordinator(
        cacheStore: MemoryCacheStore(),
        yahooClient: provider,
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 6_000)
    )

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )
    await gate.waitUntilStarted()

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )

    await gate.release()
    try await Task.sleep(for: .milliseconds(1_200))

    let snapshot = await coordinator.snapshot()
    #expect(snapshot.quotesBySymbol["AAPL"] != nil)
    #expect(await provider.fetchCount == 1)
}

@Test func failedFetchKeepsCachedDataWithErrorStatus() async throws {
    let cacheStore = MemoryCacheStore(quotes: ["AAPL": makeCachedQuote(symbol: "AAPL", fetchedAt: 1_000)])
    let coordinator = MarketRefreshCoordinator(
        cacheStore: cacheStore,
        yahooClient: StubMarketDataProvider(shouldFail: true),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 9_000)
    )

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )
    try await Task.sleep(for: .milliseconds(80))

    let snapshot = await coordinator.snapshot()
    let cached = snapshot.quotesBySymbol["AAPL"]
    #expect(cached?.data.price == 100)
    #expect(cached?.metadata.status == .error)
    #expect(cached?.metadata.source == .cache)
    #expect(cached?.metadata.error != nil)
}

@Test func failedColdStartSetsGlobalRefreshError() async throws {
    let coordinator = MarketRefreshCoordinator(
        cacheStore: MemoryCacheStore(),
        yahooClient: StubMarketDataProvider(shouldFail: true),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 9_500)
    )

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )
    try await Task.sleep(for: .milliseconds(80))

    let snapshot = await coordinator.snapshot()
    #expect(snapshot.quotesBySymbol["AAPL"] == nil)
    #expect(snapshot.refreshErrorMessage != nil)
}

@Test func activeSnapshotPrunesUnrequestedSymbolsWithoutClearingCache() async throws {
    let cacheStore = MemoryCacheStore(quotes: [
        "AAPL": makeCachedQuote(symbol: "AAPL", fetchedAt: 1_000),
        "MSFT": makeCachedQuote(symbol: "MSFT", fetchedAt: 1_000)
    ])
    let coordinator = MarketRefreshCoordinator(
        cacheStore: cacheStore,
        yahooClient: StubMarketDataProvider(delay: .milliseconds(20)),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 10_000)
    )

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )
    try await Task.sleep(for: .milliseconds(80))

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .keyMarkets, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["MSFT"])
    )

    let snapshot = await coordinator.snapshot()
    #expect(snapshot.quotesBySymbol["AAPL"] == nil)
    #expect(snapshot.quotesBySymbol["MSFT"] != nil)
    #expect(try await cacheStore.loadMarketQuote(key: "quote:AAPL", nowMs: 10_000) != nil)
}

@Test func usdCurrencyFetchUsesDollarIndexButKeepsExchangeRateFixed() async throws {
    let coordinator = MarketRefreshCoordinator(
        cacheStore: MemoryCacheStore(),
        yahooClient: StubMarketDataProvider(),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 10_500)
    )

    await coordinator.refreshOnPullToRefresh(
        holdings: [],
        widgetSettings: [WidgetSetting(widget: .currencies, isHidden: false, order: 0)],
        currencySettings: CurrencyWidgetSetting(symbols: ["USD"]),
        marketTickerSettings: MarketTickerSetting(symbols: [])
    )
    try await Task.sleep(for: .milliseconds(80))

    let quote = await coordinator.snapshot().quotesBySymbol["USD"]?.data
    #expect(quote?.price == 1)
    #expect(quote?.changePercent == 1)
    #expect(quote?.providerSymbol == YahooFinanceClient.usDollarIndexSymbol)
}
