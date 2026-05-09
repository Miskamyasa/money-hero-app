import Foundation
import Testing
@testable import MoneyHero

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
        previousClose: -1,
        change: 191,
        changePercent: 1,
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
