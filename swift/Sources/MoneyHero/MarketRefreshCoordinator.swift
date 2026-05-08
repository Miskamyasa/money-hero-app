import Foundation

public struct MarketRefreshSnapshot: Sendable {
    public let quotesBySymbol: [String: CachedMarketQuote]
    public let historiesBySymbol: [String: CachedHistoricalPrices]
    public let progress: MarketFetchQueueProgress
    public let lastUpdatedAtMs: Int?

    public init(
        quotesBySymbol: [String: CachedMarketQuote],
        historiesBySymbol: [String: CachedHistoricalPrices],
        progress: MarketFetchQueueProgress,
        lastUpdatedAtMs: Int?
    ) {
        self.quotesBySymbol = quotesBySymbol
        self.historiesBySymbol = historiesBySymbol
        self.progress = progress
        self.lastUpdatedAtMs = lastUpdatedAtMs
    }
}

private enum TrackedSymbolKind: Sendable {
    case market
    case currency
}

private struct TrackedSymbolRequest: Sendable {
    let symbol: String
    let kind: TrackedSymbolKind
}

public actor MarketRefreshCoordinator {
    private let cacheStore: LocalJSONCacheStore
    private let yahooClient: YahooFinanceClient
    private let parser: YahooChartParser
    private let fetchQueue: MarketFetchQueue

    private let schemaVersion = 1
    private let quoteStaleAfterMs = 20 * 60 * 1000
    private let quoteExpiresAfterMs = 24 * 60 * 60 * 1000
    private let historyStaleAfterMs = 24 * 60 * 60 * 1000
    private let historyExpiresAfterMs = 7 * 24 * 60 * 60 * 1000

    private(set) var quotesBySymbol: [String: CachedMarketQuote] = [:]
    private(set) var historiesBySymbol: [String: CachedHistoricalPrices] = [:]
    private(set) var lastUpdatedAtMs: Int?
    private(set) var progress: MarketFetchQueueProgress = .init(totalCount: 0, completedCount: 0, running: false, currentLabel: nil)

    public init(
        cacheStore: LocalJSONCacheStore,
        yahooClient: YahooFinanceClient = YahooFinanceClient(),
        parser: YahooChartParser = YahooChartParser(),
        fetchQueue: MarketFetchQueue = MarketFetchQueue()
    ) {
        self.cacheStore = cacheStore
        self.yahooClient = yahooClient
        self.parser = parser
        self.fetchQueue = fetchQueue
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
            lastUpdatedAtMs: lastUpdatedAtMs
        )
    }

    private func refresh(
        holdings: [Holding],
        widgetSettings: [WidgetSetting],
        currencySettings: CurrencyWidgetSetting,
        marketTickerSettings: MarketTickerSetting
    ) async {
        let activeWidgets = activeWidgets(from: widgetSettings, hasHoldings: !holdings.isEmpty)
        let requests = Self.trackedRequests(
            activeWidgets: activeWidgets,
            holdings: holdings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
        let symbols = requests.map(\.symbol)

        await hydrateCache(symbols: symbols)

        _ = await fetchQueue.clearPending()
        await setProgressFromQueue()

        for request in requests {
            let symbol = request.symbol
            let quoteTask = MarketFetchQueueTask(cacheKey: quoteCacheKey(symbol: symbol), label: "Quote \(symbol)") { [weak self] in
                guard let self else {
                    return
                }
                await self.runQuoteAndHistoryFetch(symbol: symbol, kind: request.kind)
            }
            _ = await fetchQueue.enqueue(task: quoteTask, completion: queueCompletion)
        }

        await setProgressFromQueue()
    }

    private var queueCompletion: MarketFetchQueue.Completion {
        { [weak self] _ in
            guard let self else {
                return
            }
            Task {
                await self.setProgressFromQueue()
            }
        }
    }

    private func hydrateCache(symbols: [String]) async {
        let nowMs = nowMilliseconds()

        for symbol in symbols {
            if let cachedQuote = try? await cacheStore.loadMarketQuote(key: quoteCacheKey(symbol: symbol), nowMs: nowMs) {
                quotesBySymbol[symbol] = cachedQuote
            }

            if let cachedHistory = try? await cacheStore.loadHistoricalPrices(key: historyCacheKey(symbol: symbol), nowMs: nowMs) {
                historiesBySymbol[symbol] = cachedHistory
            }
        }

        updateLastUpdatedFromCache()
    }

    private func runQuoteAndHistoryFetch(symbol: String, kind: TrackedSymbolKind) async {
        do {
            let normalized = try normalizeSymbol(symbol)

            if kind == .currency {
                let response = try await yahooClient.fetchCurrencyChart(displayedCurrency: normalized)
                let quote = try parser.parseCurrencyQuote(
                    data: response.data,
                    requestedSymbol: normalized,
                    displayedCurrency: normalized,
                    invertForUSDDisplay: true
                )
                try await persistSuccess(symbol: normalized, quote: quote, history: nil)
                return
            }

            if normalized == YahooFinanceClient.goldSymbol {
                let quoteResponse = try await yahooClient.fetchGoldQuoteChart()
                let historyResponse = try await yahooClient.fetchGoldHistoryChart()
                let parsed = try parser.parseGoldQuoteAndHistory(quoteData: quoteResponse.data, historyData: historyResponse.data)
                try await persistSuccess(symbol: normalized, quote: parsed.quote, history: parsed.history)
                return
            }

            let response = try await yahooClient.fetchStockChart(symbol: normalized)
            let parsed = try parser.parseStockQuoteAndHistory(data: response.data, requestedSymbol: normalized)
            try await persistSuccess(symbol: normalized, quote: parsed.quote, history: parsed.history)
        } catch {
            await applyFailure(symbol: symbol, errorMessage: String(describing: error))
            await setProgressFromQueue()
        }
    }

    private func persistSuccess(symbol: String, quote: MarketQuote, history: HistoricalPriceSeries?) async throws {
        let nowMs = nowMilliseconds()

        let quoteEnvelope = CachedMarketQuote(
            metadata: LocalCacheMetadata(
                key: quoteCacheKey(symbol: symbol),
                kind: .marketQuote,
                provider: .yahoo,
                symbol: symbol,
                fetchedAt: nowMs,
                staleAt: nowMs + quoteStaleAfterMs,
                expiresAt: nowMs + quoteExpiresAfterMs,
                writtenAt: nowMs,
                status: .fresh,
                source: .network,
                schemaVersion: schemaVersion,
                etag: nil,
                error: nil
            ),
            data: quote
        )

        try await cacheStore.saveMarketQuote(quoteEnvelope)
        quotesBySymbol[symbol] = quoteEnvelope

        if let history {
            let historyEnvelope = CachedHistoricalPrices(
                metadata: LocalCacheMetadata(
                    key: historyCacheKey(symbol: symbol),
                    kind: .historicalPrices,
                    provider: .yahoo,
                    symbol: symbol,
                    fetchedAt: nowMs,
                    staleAt: nowMs + historyStaleAfterMs,
                    expiresAt: nowMs + historyExpiresAfterMs,
                    writtenAt: nowMs,
                    status: .fresh,
                    source: .network,
                    schemaVersion: schemaVersion,
                    etag: nil,
                    error: nil
                ),
                data: history
            )

            try await cacheStore.saveHistoricalPrices(historyEnvelope)
            historiesBySymbol[symbol] = historyEnvelope
        }

        updateLastUpdatedFromCache()
    }

    private func applyFailure(symbol: String, errorMessage: String) async {
        let nowMs = nowMilliseconds()
        let normalizedSymbol = (try? normalizeSymbol(symbol)) ?? symbol

        if let existingQuote = quotesBySymbol[normalizedSymbol] {
            let metadata = LocalCacheMetadata(
                key: existingQuote.metadata.key,
                kind: existingQuote.metadata.kind,
                provider: existingQuote.metadata.provider,
                symbol: existingQuote.metadata.symbol,
                fetchedAt: existingQuote.metadata.fetchedAt,
                staleAt: existingQuote.metadata.staleAt,
                expiresAt: existingQuote.metadata.expiresAt,
                writtenAt: nowMs,
                status: .error,
                source: .cache,
                schemaVersion: existingQuote.metadata.schemaVersion,
                etag: existingQuote.metadata.etag,
                error: errorMessage
            )
            let failedEnvelope = CachedMarketQuote(metadata: metadata, data: existingQuote.data)
            quotesBySymbol[normalizedSymbol] = failedEnvelope
            try? await cacheStore.saveMarketQuote(failedEnvelope)
        }

        if let existingHistory = historiesBySymbol[normalizedSymbol] {
            let metadata = LocalCacheMetadata(
                key: existingHistory.metadata.key,
                kind: existingHistory.metadata.kind,
                provider: existingHistory.metadata.provider,
                symbol: existingHistory.metadata.symbol,
                fetchedAt: existingHistory.metadata.fetchedAt,
                staleAt: existingHistory.metadata.staleAt,
                expiresAt: existingHistory.metadata.expiresAt,
                writtenAt: nowMs,
                status: .error,
                source: .cache,
                schemaVersion: existingHistory.metadata.schemaVersion,
                etag: existingHistory.metadata.etag,
                error: errorMessage
            )
            let failedEnvelope = CachedHistoricalPrices(metadata: metadata, data: existingHistory.data)
            historiesBySymbol[normalizedSymbol] = failedEnvelope
            try? await cacheStore.saveHistoricalPrices(failedEnvelope)
        }
    }

    private func updateLastUpdatedFromCache() {
        let quoteTimes = quotesBySymbol.values.map { $0.metadata.lastUpdatedAtMs }
        let historyTimes = historiesBySymbol.values.map { $0.metadata.lastUpdatedAtMs }
        lastUpdatedAtMs = (quoteTimes + historyTimes).max()
    }

    private func setProgressFromQueue() async {
        progress = await fetchQueue.progress
    }

    private func activeWidgets(from settings: [WidgetSetting], hasHoldings: Bool) -> [DashboardWidget] {
        settings
            .filter { !$0.isHidden }
            .sorted { $0.order < $1.order }
            .map(\.widget)
            .filter { hasHoldings || !$0.requiresHoldings }
    }

    public nonisolated static func trackedSymbols(
        activeWidgets: [DashboardWidget],
        holdings: [Holding],
        currencySettings: CurrencyWidgetSetting,
        marketTickerSettings: MarketTickerSetting
    ) -> [String] {
        trackedRequests(
            activeWidgets: activeWidgets,
            holdings: holdings,
            currencySettings: currencySettings,
            marketTickerSettings: marketTickerSettings
        )
        .map(\.symbol)
    }

    private nonisolated static func trackedRequests(
        activeWidgets: [DashboardWidget],
        holdings: [Holding],
        currencySettings: CurrencyWidgetSetting,
        marketTickerSettings: MarketTickerSetting
    ) -> [TrackedSymbolRequest] {
        var requests: [TrackedSymbolRequest] = []

        if activeWidgets.contains(.keyMarkets) {
            requests.append(
                contentsOf: marketTickerSettings.symbols.compactMap { symbol in
                    guard let normalized = try? normalizeSymbol(symbol) else {
                        return nil
                    }
                    return TrackedSymbolRequest(symbol: normalized, kind: .market)
                }
            )
        }
        if activeWidgets.contains(.currencies) {
            requests.append(
                contentsOf: currencySettings.symbols.compactMap { symbol in
                    guard let normalized = Self.fetchableCurrencySymbol(symbol) else {
                        return nil
                    }
                    return TrackedSymbolRequest(symbol: normalized, kind: .currency)
                }
            )
        }

        for holding in holdings {
            guard !holding.isHidden else {
                continue
            }
            if let normalized = try? normalizeSymbol(holding.symbol) {
                requests.append(TrackedSymbolRequest(symbol: normalized, kind: .market))
            }
        }

        var seen: Set<String> = []
        return requests.filter { seen.insert($0.symbol).inserted }
    }

    private nonisolated static func fetchableCurrencySymbol(_ symbol: String) -> String? {
        guard let normalized = try? normalizeCurrencyCode(symbol), normalized != "USD" else {
            return nil
        }

        return normalized
    }

    private func quoteCacheKey(symbol: String) -> String {
        "quote:\(symbol)"
    }

    private func historyCacheKey(symbol: String) -> String {
        "history:\(symbol)"
    }

    private func nowMilliseconds() -> Int {
        Int(Date().timeIntervalSince1970 * 1000)
    }
}
