part of "yahoo_chart_parser.dart";

class _YahooResult {
  const _YahooResult({required this.meta, required this.timestamp, required this.open, required this.high, required this.low, required this.close, required this.adjustedClose, required this.volume, required this.eventsDividends});

  final _YahooMeta meta;
  final List<int> timestamp;
  final List<double?> open;
  final List<double?> high;
  final List<double?> low;
  final List<double?> close;
  final List<double?> adjustedClose;
  final List<double?> volume;
  final Map<String, dynamic>? eventsDividends;

  factory _YahooResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> indicators = json["indicators"] as Map<String, dynamic>? ?? <String, dynamic>{};
    final List<dynamic> quote = indicators["quote"] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> quote0 = quote.isNotEmpty ? quote.first as Map<String, dynamic> : <String, dynamic>{};
    final List<dynamic> adjclose = indicators["adjclose"] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> adj0 = adjclose.isNotEmpty ? adjclose.first as Map<String, dynamic> : <String, dynamic>{};
    final Map<String, dynamic>? events = json["events"] as Map<String, dynamic>?;
    return _YahooResult(
      meta: _YahooMeta.fromJson(json["meta"] as Map<String, dynamic>? ?? <String, dynamic>{}),
      timestamp: (json["timestamp"] as List<dynamic>? ?? <dynamic>[]).map((dynamic item) => item as int).toList(),
      open: _toNullableDoubleList(quote0["open"] as List<dynamic>? ?? <dynamic>[]),
      high: _toNullableDoubleList(quote0["high"] as List<dynamic>? ?? <dynamic>[]),
      low: _toNullableDoubleList(quote0["low"] as List<dynamic>? ?? <dynamic>[]),
      close: _toNullableDoubleList(quote0["close"] as List<dynamic>? ?? <dynamic>[]),
      adjustedClose: _toNullableDoubleList(adj0["adjclose"] as List<dynamic>? ?? <dynamic>[]),
      volume: _toNullableDoubleList(quote0["volume"] as List<dynamic>? ?? <dynamic>[]),
      eventsDividends: events?["dividends"] as Map<String, dynamic>?,
    );
  }
}

class _YahooMeta {
  const _YahooMeta({required this.symbol, required this.currency, required this.longName, required this.shortName, required this.regularMarketPrice, required this.chartPreviousClose, required this.regularMarketTime, required this.exchangeTimezoneName});

  final String? symbol;
  final String? currency;
  final String? longName;
  final String? shortName;
  final double? regularMarketPrice;
  final double? chartPreviousClose;
  final int? regularMarketTime;
  final String? exchangeTimezoneName;

  factory _YahooMeta.fromJson(Map<String, dynamic> json) {
    return _YahooMeta(
      symbol: json["symbol"] as String?,
      currency: json["currency"] as String?,
      longName: json["longName"] as String?,
      shortName: json["shortName"] as String?,
      regularMarketPrice: (json["regularMarketPrice"] as num?)?.toDouble(),
      chartPreviousClose: (json["chartPreviousClose"] as num?)?.toDouble(),
      regularMarketTime: json["regularMarketTime"] as int?,
      exchangeTimezoneName: json["exchangeTimezoneName"] as String?,
    );
  }
}

List<double?> _toNullableDoubleList(List<dynamic> values) {
  return values.map((dynamic item) => item == null ? null : (item as num).toDouble()).toList();
}
