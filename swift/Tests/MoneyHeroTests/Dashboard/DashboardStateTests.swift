import Testing
@testable import MoneyHero

@MainActor
@Test func dashboardStateTogglesLoadingAndRefreshing() async throws {
    let coordinator = MarketRefreshCoordinator(
        cacheStore: MemoryCacheStore(),
        yahooClient: StubMarketDataProvider(delay: .milliseconds(80)),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 8_000)
    )
    let state = DashboardState(
        coordinator: coordinator,
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )

    let refreshTask = Task {
        await state.refreshOnAppOpen()
    }
    try await Task.sleep(for: .milliseconds(20))
    #expect(state.isInitialLoading == true)
    #expect(state.isRefreshing == true)

    try await Task.sleep(for: .milliseconds(160))
    await refreshTask.value
    #expect(state.isInitialLoading == false)
    #expect(state.isRefreshing == false)
    #expect(state.snapshot.quotesBySymbol["AAPL"] != nil)
}

@MainActor
@Test func dashboardStateClearsLoadingForEmptyRefresh() async throws {
    let coordinator = MarketRefreshCoordinator(
        cacheStore: MemoryCacheStore(),
        yahooClient: StubMarketDataProvider(),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 8_500)
    )
    let state = DashboardState(
        coordinator: coordinator,
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: [])
    )

    await state.refreshOnAppOpen()

    #expect(state.isInitialLoading == false)
    #expect(state.isRefreshing == false)
    #expect(state.snapshot.progress.totalCount == 0)
}

@MainActor
@Test func dashboardStateSurfacesColdStartRefreshError() async throws {
    let coordinator = MarketRefreshCoordinator(
        cacheStore: MemoryCacheStore(),
        yahooClient: StubMarketDataProvider(shouldFail: true),
        parser: StubMarketChartParser(),
        fetchQueue: MarketFetchQueue(),
        clock: FixedClockProvider(nowMs: 9_750)
    )
    let state = DashboardState(
        coordinator: coordinator,
        currencySettings: CurrencyWidgetSetting(symbols: []),
        marketTickerSettings: MarketTickerSetting(symbols: ["AAPL"])
    )

    await state.refreshOnAppOpen()
    try await Task.sleep(for: .milliseconds(80))

    #expect(state.refreshErrorMessage != nil)
    #expect(state.isAppOpenLoading == false)
}
