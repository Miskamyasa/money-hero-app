import Foundation

public actor MarketRefreshCoordinator {
    let cacheStore: any MarketCacheStoring
    private let yahooClient: any MarketDataProviding
    private let parser: any MarketChartParsing
    let fetchQueue: MarketFetchQueue
    let clock: any ClockProviding
    let quoteFetcher: MarketQuoteFetcher

    private let schemaVersion = 1
    private let quoteStaleAfterMs = 20 * 60 * 1000
    private let quoteExpiresAfterMs = 24 * 60 * 60 * 1000
    private let historyStaleAfterMs = 24 * 60 * 60 * 1000
    private let historyExpiresAfterMs = 7 * 24 * 60 * 60 * 1000
    let cacheEnvelopeFactory: MarketRefreshCacheEnvelopeFactory
    let cacheHydrator: MarketRefreshCacheHydrator

    var quotesBySymbol: [String: CachedMarketQuote] = [:]
    var historiesBySymbol: [String: CachedHistoricalPrices] = [:]
    var lastUpdatedAtMs: Int?
    var refreshErrorMessage: String?
    var progress: MarketFetchQueueProgress = .init(totalCount: 0, completedCount: 0, running: false, currentLabel: nil)
    var refreshRunID = 0
    var refreshIsActive = false
    var refreshHasQueuedWork = false
    var observesQueueProgress = false
    var snapshotBroadcaster = MarketRefreshSnapshotBroadcaster()

    public init(
        cacheStore: any MarketCacheStoring,
        yahooClient: any MarketDataProviding = YahooFinanceClient(),
        parser: any MarketChartParsing = YahooChartParser(),
        fetchQueue: MarketFetchQueue = MarketFetchQueue(),
        clock: any ClockProviding = SystemClockProvider()
    ) {
        self.cacheStore = cacheStore
        self.yahooClient = yahooClient
        self.parser = parser
        self.fetchQueue = fetchQueue
        self.clock = clock
        self.quoteFetcher = MarketQuoteFetcher(provider: yahooClient, parser: parser)
        let cacheEnvelopeFactory = MarketRefreshCacheEnvelopeFactory(
            schemaVersion: schemaVersion,
            quoteStaleAfterMs: quoteStaleAfterMs,
            quoteExpiresAfterMs: quoteExpiresAfterMs,
            historyStaleAfterMs: historyStaleAfterMs,
            historyExpiresAfterMs: historyExpiresAfterMs
        )
        self.cacheEnvelopeFactory = cacheEnvelopeFactory
        self.cacheHydrator = MarketRefreshCacheHydrator(
            cacheStore: cacheStore,
            cacheEnvelopeFactory: cacheEnvelopeFactory,
            clock: clock
        )
    }

    public nonisolated func snapshots() -> AsyncStream<MarketRefreshSnapshot> {
        AsyncStream { continuation in
            let id = UUID()
            Task {
                await self.addSnapshotContinuation(id: id, continuation: continuation)
            }
            continuation.onTermination = { @Sendable _ in
                Task {
                    await self.removeSnapshotContinuation(id: id)
                }
            }
        }
    }

    public func refreshOnAppOpen(
        holdings: [Holding],
        widgetSettings: [WidgetSetting] = WidgetDefaults.mvp,
        currencySettings: CurrencyWidgetSetting = .default,
        marketTickerSettings: MarketTickerSetting = .default
    ) async {
        await refresh(
            holdings: holdings,
            widgetSettings: widgetSettings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
    }

    public func refreshOnPullToRefresh(
        holdings: [Holding],
        widgetSettings: [WidgetSetting] = WidgetDefaults.mvp,
        currencySettings: CurrencyWidgetSetting = .default,
        marketTickerSettings: MarketTickerSetting = .default
    ) async {
        await refresh(
            holdings: holdings,
            widgetSettings: widgetSettings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
    }

    public func snapshot() -> MarketRefreshSnapshot {
        MarketRefreshSnapshot(
            quotesBySymbol: quotesBySymbol,
            historiesBySymbol: historiesBySymbol,
            progress: progress,
            lastUpdatedAtMs: lastUpdatedAtMs,
            refreshErrorMessage: refreshErrorMessage
        )
    }

    private func refresh(
        holdings: [Holding],
        widgetSettings: [WidgetSetting],
        currencySettings: CurrencyWidgetSetting,
        marketTickerSettings: MarketTickerSetting
    ) async {
        guard !refreshIsActive else {
            return
        }

        refreshIsActive = true
        refreshHasQueuedWork = false
        refreshErrorMessage = nil

        refreshRunID += 1
        let runID = refreshRunID
        await observeQueueProgressIfNeeded()

        let activeWidgets = MarketRefreshActiveWidgetPlanner.activeWidgets(
            from: widgetSettings,
            hasHoldings: !holdings.isEmpty
        )
        let requests = MarketRefreshRequestPlanner.trackedRequests(
            activeWidgets: activeWidgets,
            holdings: holdings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
        let symbols = requests.map(\.symbol)

        progress = await fetchQueue.clearPending(resetCompletedCount: true)
        pruneActiveSnapshots(to: symbols)

        await hydrateCache(symbols: symbols)
        emitSnapshot()

        guard !requests.isEmpty else {
            refreshIsActive = false
            return
        }

        refreshHasQueuedWork = true
        for request in requests {
            let symbol = request.symbol
            let quoteTask = MarketFetchQueueTask(cacheKey: quoteCacheKey(symbol: symbol), label: "Quote \(symbol)") { [weak self] in
                guard let self else {
                    return
                }
                await self.runQuoteAndHistoryFetch(symbol: symbol, kind: request.kind, runID: runID)
            }
            _ = await fetchQueue.enqueue(task: quoteTask, completion: queueCompletion)
        }

        await setProgressFromQueue()
    }

    private func runQuoteAndHistoryFetch(symbol: String, kind: MarketRefreshTrackedSymbolKind, runID: Int) async {
        guard runID == refreshRunID else {
            return
        }

        do {
            let result = try await quoteFetcher.fetch(symbol: symbol, kind: kind)
            guard runID == refreshRunID else {
                return
            }
            try await persistSuccess(symbol: result.symbol, quote: result.quote, history: result.history)
        } catch {
            guard runID == refreshRunID else {
                return
            }
            await applyFailure(symbol: symbol, errorMessage: String(describing: error))
            await setProgressFromQueue()
        }
    }

    public nonisolated static func trackedSymbols(
        activeWidgets: [DashboardWidget],
        holdings: [Holding],
        currencySettings: CurrencyWidgetSetting,
        marketTickerSettings: MarketTickerSetting
    ) -> [String] {
        MarketRefreshRequestPlanner.trackedSymbols(
            activeWidgets: activeWidgets,
            holdings: holdings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
    }

}
