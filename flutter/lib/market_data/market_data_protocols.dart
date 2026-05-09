import "dart:typed_data";

import "../domain/market_cache_models.dart";
import "../domain/market_history_models.dart";
import "../domain/market_quote_models.dart";

abstract interface class MarketCacheStore {
  Future<void> saveMarketQuote(CachedMarketQuote envelope);
  Future<void> saveHistoricalPrices(CachedHistoricalPrices envelope);
  Future<CachedMarketQuote?> loadMarketQuote({required String key, required int nowMs});
  Future<CachedHistoricalPrices?> loadHistoricalPrices({required String key, required int nowMs});
}

abstract interface class MarketDataProviding {
  Future<YahooHttpResponse> fetchStockChart({required String symbol});
  Future<YahooHttpResponse> fetchCurrencyChart({required String displayedCurrency});
  Future<YahooHttpResponse> fetchGoldQuoteChart();
  Future<YahooHttpResponse> fetchGoldHistoryChart();
}

abstract interface class MarketChartParser {
  ({MarketQuote quote, HistoricalPriceSeries history}) parseStockQuoteAndHistory({
    required Uint8List data,
    required String requestedSymbol,
  });
  MarketQuote parseCurrencyQuote({
    required Uint8List data,
    required String requestedSymbol,
    required String displayedCurrency,
    required bool invertForUsdDisplay,
  });
  ({MarketQuote quote, HistoricalPriceSeries history}) parseGoldQuoteAndHistory({
    required Uint8List quoteData,
    required Uint8List historyData,
  });
}

abstract interface class ClockProvider {
  int nowMilliseconds();
}

class SystemClockProvider implements ClockProvider {
  const SystemClockProvider();

  @override
  int nowMilliseconds() => DateTime.now().millisecondsSinceEpoch;
}

class YahooHttpResponse {
  const YahooHttpResponse({
    required this.requestUrl,
    required this.statusCode,
    required this.data,
  });

  final Uri requestUrl;
  final int statusCode;
  final Uint8List data;
}
