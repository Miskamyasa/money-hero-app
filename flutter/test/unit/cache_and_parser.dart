part of "../money_hero_test.dart";

void registerCacheAndParserTests() {
  test("invalid cache envelope rejection", () async {
    final LocalJsonCacheStore store = LocalJsonCacheStore();
    final CachedMarketQuote envelope = CachedMarketQuote(
      metadata: const LocalCacheMetadata(key: "quote:AAPL", kind: CacheKind.marketQuote, provider: MarketDataProvider.yahoo, symbol: "AAPL", fetchedAt: 10, staleAt: 20, expiresAt: 30, writtenAt: 15, status: CacheStatus.fresh, source: CacheSource.network, schemaVersion: 1, etag: null, error: null),
      data: const MarketQuote(symbol: "AAPL", providerSymbol: null, name: "Apple", provider: MarketDataProvider.yahoo, price: 1, previousClose: -1, change: 2, changePercent: 100, currency: "USD", marketTime: null, exchangeTimezoneName: null, change1m: null, change6m: null, change1y: null, change2y: null, dividends: <DividendEvent>[]),
    );
    await expectLater(store.saveMarketQuote(envelope), throwsA(LocalJsonCacheValidationError.invalidPayload));
  });

  test("missing yahoo result parser failure", () {
    final YahooChartParser parser = YahooChartParser();
    expect(
      () => parser.parseCurrencyQuote(data: Uint8List.fromList(utf8.encode('{"chart":{"result":null}}')), requestedSymbol: "EURUSD=X", displayedCurrency: "EUR", invertForUsdDisplay: false),
      throwsA(isA<YahooChartParserError>()),
    );
  });

  test("usd currency fetch keeps price fixed", () async {
    final MarketQuoteFetcher fetcher = MarketQuoteFetcher(provider: _StubProvider(), parser: _StubParser());
    final MarketQuoteFetchResult result = await fetcher.fetch(symbol: "USD", kind: MarketRefreshTrackedSymbolKind.currency);
    expect(result.quote.price, 1);
    expect(result.quote.previousClose, 1);
    expect(result.quote.changePercent, 0);
    expect(result.quote.providerSymbol, null);
  });
}
