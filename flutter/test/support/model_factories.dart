part of "../money_hero_test.dart";

CachedMarketQuote cachedQuote(String symbol, double price) {
  return CachedMarketQuote(
    metadata: LocalCacheMetadata(key: "quote:$symbol", kind: CacheKind.marketQuote, provider: MarketDataProvider.yahoo, symbol: symbol, fetchedAt: 1000, staleAt: 2000, expiresAt: 3000, writtenAt: 1500, status: CacheStatus.fresh, source: CacheSource.network, schemaVersion: 1, etag: null, error: null),
    data: makeQuote(symbol: symbol, price: price),
  );
}

MarketQuote makeQuote({required String symbol, required double price, String currency = "USD", String? providerSymbol}) {
  return MarketQuote(symbol: symbol, providerSymbol: providerSymbol, name: symbol, provider: MarketDataProvider.yahoo, price: price, previousClose: price - 1, change: 1, changePercent: 1, currency: currency, marketTime: null, exchangeTimezoneName: null, change1m: 1, change6m: 1, change1y: 1, change2y: 1, dividends: const <DividendEvent>[]);
}

HistoricalPriceSeries makeHistory(String symbol) {
  return HistoricalPriceSeries(
    symbol: symbol,
    providerSymbol: null,
    provider: MarketDataProvider.yahoo,
    currency: "USD",
    interval: HistoricalPriceInterval.oneDay,
    range: HistoricalPriceRange.twoYears,
    prices: <HistoricalPrice>[HistoricalPrice(symbol: symbol, providerSymbol: null, provider: MarketDataProvider.yahoo, currency: "USD", timestamp: 1, date: "1970-01-01", open: 99, high: 101, low: 98, close: 100, adjustedClose: 100, volume: 1)],
  );
}
