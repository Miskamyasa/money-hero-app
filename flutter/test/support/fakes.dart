part of "../money_hero_test.dart";

class _MemoryCacheStore implements MarketCacheStore {
  final Map<String, CachedMarketQuote> quotes = <String, CachedMarketQuote>{};
  final Map<String, CachedHistoricalPrices> histories = <String, CachedHistoricalPrices>{};

  @override
  Future<CachedHistoricalPrices?> loadHistoricalPrices({required String key, required int nowMs}) async {
    final CachedHistoricalPrices? history = histories[key];
    if (history == null) {
      return null;
    }
    return CachedHistoricalPrices(metadata: history.metadata.copyWith(source: CacheSource.cache), data: history.data);
  }

  @override
  Future<CachedMarketQuote?> loadMarketQuote({required String key, required int nowMs}) async {
    final CachedMarketQuote? quote = quotes[key];
    if (quote == null) {
      return null;
    }
    return CachedMarketQuote(metadata: quote.metadata.copyWith(source: CacheSource.cache), data: quote.data);
  }

  @override
  Future<void> saveHistoricalPrices(CachedHistoricalPrices envelope) async {
    histories[envelope.metadata.key] = envelope;
  }

  @override
  Future<void> saveMarketQuote(CachedMarketQuote envelope) async {
    quotes[envelope.metadata.key] = envelope;
  }
}

class _StubProvider implements MarketDataProviding {
  _StubProvider({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<YahooHttpResponse> fetchCurrencyChart({required String displayedCurrency}) async => _response(displayedCurrency);

  @override
  Future<YahooHttpResponse> fetchGoldHistoryChart() async => _response("GC=F");

  @override
  Future<YahooHttpResponse> fetchGoldQuoteChart() async => _response("GC=F");

  @override
  Future<YahooHttpResponse> fetchStockChart({required String symbol}) async => _response(symbol);

  Future<YahooHttpResponse> _response(String symbol) async {
    if (shouldFail) {
      throw Exception("failed");
    }
    return YahooHttpResponse(requestUrl: Uri(path: symbol), statusCode: 200, data: Uint8List(0));
  }
}

class _StubParser implements MarketChartParser {
  @override
  ({HistoricalPriceSeries history, MarketQuote quote}) parseGoldQuoteAndHistory({required Uint8List quoteData, required Uint8List historyData}) => parseStockQuoteAndHistory(data: Uint8List(0), requestedSymbol: "GC=F");

  @override
  MarketQuote parseCurrencyQuote({required Uint8List data, required String requestedSymbol, required String displayedCurrency, required bool invertForUsdDisplay}) {
    return makeQuote(symbol: displayedCurrency, price: 1.1, currency: displayedCurrency);
  }

  @override
  ({HistoricalPriceSeries history, MarketQuote quote}) parseStockQuoteAndHistory({required Uint8List data, required String requestedSymbol}) {
    final String symbol = normalizeSymbol(requestedSymbol);
    final MarketQuote quote = makeQuote(symbol: symbol, price: 100);
    return (quote: quote, history: makeHistory(symbol));
  }
}
