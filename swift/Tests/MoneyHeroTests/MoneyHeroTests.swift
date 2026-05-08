import Foundation
import Testing
@testable import MoneyHero

@Test func rootViewCanInitialize() {
    _ = RootView()
}

@Test func normalizeSymbolTrimsAndUppercases() throws {
    let symbol = try normalizeSymbol("  aapl  ")
    #expect(symbol == "AAPL")
}

@Test func normalizeCurrencyAndPriceConvertsSubunits() throws {
    let gbp = try normalizeCurrencyAndPrice(currency: "GBp", price: 123.0)
    #expect(gbp.currency == "GBP")
    #expect(gbp.price == 1.23)

    let ils = try normalizeCurrencyAndPrice(currency: "ILA", price: 455.0)
    #expect(ils.currency == "ILS")
    #expect(ils.price == 4.55)
}

@Test func loadMarketQuoteDropsInvalidCachedEnvelope() async throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("MoneyHeroTests")
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    let store = try LocalJSONCacheStore(directoryURL: tempRoot)
    let key = "quote_invalid_payload"
    let now = 1_800_000
    let metadata = LocalCacheMetadata(
        key: key,
        kind: .marketQuote,
        provider: .yahoo,
        symbol: "AAPL",
        fetchedAt: 1_000,
        staleAt: 2_000,
        expiresAt: 3_000,
        writtenAt: 1_500,
        status: .fresh,
        source: .network,
        schemaVersion: 1,
        etag: nil,
        error: nil
    )
    let invalidQuote = MarketQuote(
        symbol: "AAPL",
        providerSymbol: nil,
        name: "Apple",
        provider: .yahoo,
        price: 190,
        previousClose: 0,
        change: 190,
        changePercent: .infinity,
        currency: "USD",
        marketTime: nil,
        exchangeTimezoneName: nil,
        change1m: nil,
        change6m: nil,
        change1y: nil,
        change2y: nil,
        dividends: []
    )

    let envelope = CachedMarketQuote(metadata: metadata, data: invalidQuote)
    let encoded = try JSONEncoder().encode(envelope)
    let fileURL = tempRoot.appendingPathComponent("market-quote_\(key).json")
    try encoded.write(to: fileURL)

    let loaded = try await store.loadMarketQuote(key: key, nowMs: now)
    #expect(loaded == nil)
    #expect(FileManager.default.fileExists(atPath: fileURL.path) == false)
}

@Test func parserReturnsFailureForMissingResult() {
    let parser = YahooChartParser()
    let payload = Data("{\"chart\":{\"result\":null}}".utf8)

    #expect(throws: YahooChartParserError.missingResult) {
        try parser.parseCurrencyQuote(
            data: payload,
            requestedSymbol: "EURUSD=X",
            displayedCurrency: "EUR",
            invertForUSDDisplay: false
        )
    }
}

@Test func parserNormalizesSubunitCurrencyFromHistoryAndDividends() throws {
    let parser = YahooChartParser()
    let payload = Data(
        """
        {
          "chart": {
            "result": [
              {
                "meta": {
                  "symbol": "VOD.L",
                  "currency": "GBp",
                  "regularMarketPrice": 130,
                  "regularMarketTime": 1700000000,
                  "exchangeTimezoneName": "Europe/London",
                  "longName": "Vodafone Group"
                },
                "timestamp": [1690000000, 1700000000],
                "indicators": {
                  "quote": [
                    {
                      "open": [100, 120],
                      "high": [110, 140],
                      "low": [90, 110],
                      "close": [100, 120],
                      "volume": [1, 2]
                    }
                  ],
                  "adjclose": [
                    {
                      "adjclose": [100, 120]
                    }
                  ]
                },
                "events": {
                  "dividends": {
                    "1": {
                      "amount": 55,
                      "date": 1695000000
                    }
                  }
                }
              }
            ]
          }
        }
        """.utf8
    )

    let parsed = try parser.parseStockQuoteAndHistory(data: payload, requestedSymbol: " vod.l ")
    #expect(parsed.quote.symbol == "VOD.L")
    #expect(parsed.quote.currency == "GBP")
    #expect(parsed.quote.price == 1.3)
    #expect(parsed.quote.previousClose == 1.0)
    #expect(parsed.quote.dividends.first?.amount == 0.55)
    #expect(parsed.history.currency == "GBP")
    #expect(parsed.history.prices.count == 2)
    #expect(parsed.history.prices.last?.close == 1.2)
}

@Test func fetchQueueDeduplicatesByCacheKey() async throws {
    let queue = MarketFetchQueue()
    let counter = InvocationCounter()

    _ = await queue.enqueue(
        task: MarketFetchQueueTask(
            cacheKey: "quote:AAPL",
            label: "first"
        ) {
            await counter.increment()
        }
    )

    _ = await queue.enqueue(
        task: MarketFetchQueueTask(
            cacheKey: " quote:AAPL ",
            label: "duplicate"
        ) {
            await counter.increment()
        }
    )

    _ = await queue.enqueue(
        task: MarketFetchQueueTask(
            cacheKey: "history:AAPL",
            label: "history"
        ) {
            await counter.increment()
        }
    )

    try await Task.sleep(for: .seconds(3))

    let invocations = await counter.value
    #expect(invocations == 2)
    let progress = await queue.progress
    #expect(progress.running == false)
    #expect(progress.completedCount == 2)
}

@Test func widgetDefaultsAndCurrencyDefaultsMatchMvpContract() {
    #expect(CurrencyWidgetSetting.default.symbols == ["USD", "EUR", "GBP"])

    let expectedOrder: [DashboardWidget] = [
        .gold,
        .sp500,
        .currencies,
        .totalPortfolioBalance,
        .expectedBalanceOneYear,
        .expectedBalanceFiveYears,
        .fetchProgress
    ]

    #expect(WidgetDefaults.mvp.map(\.widget) == expectedOrder)
    #expect(WidgetDefaults.mvp.allSatisfy { $0.isHidden == false })
    #expect(DashboardWidget.totalPortfolioBalance.requiresHoldings)
    #expect(DashboardWidget.expectedBalanceOneYear.requiresHoldings)
    #expect(DashboardWidget.expectedBalanceFiveYears.requiresHoldings)
    #expect(DashboardWidget.gold.requiresHoldings == false)
    #expect(DashboardWidget.sp500.requiresHoldings == false)
    #expect(DashboardWidget.currencies.requiresHoldings == false)
    #expect(DashboardWidget.fetchProgress.requiresHoldings == false)
}

private actor InvocationCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}
