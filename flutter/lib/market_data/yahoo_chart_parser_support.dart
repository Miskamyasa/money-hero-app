part of "yahoo_chart_parser.dart";

_YahooResult _firstResult(Uint8List data) {
    final Object? decoded = jsonDecode(utf8.decode(data));
    final Map<String, dynamic> root = decoded as Map<String, dynamic>;
    final Map<String, dynamic>? chart = root["chart"] as Map<String, dynamic>?;
    final List<dynamic>? result = chart?["result"] as List<dynamic>?;
    if (result == null || result.isEmpty) {
      throw const YahooChartParserError("missingResult");
    }
    return _YahooResult.fromJson(result.first as Map<String, dynamic>);
}

HistoricalPriceSeries _buildSeries({required String symbol, required String? providerSymbol, required _YahooResult result}) {
    final String rawCurrency = _requireString(result.meta.currency, "currency");
    final String currency = normalizeCurrencyAndPrice(currency: rawCurrency, price: 1).currency;
    if (result.timestamp.isEmpty || result.close.isEmpty) {
      throw const YahooChartParserError("missingPriceSeries");
    }
    final List<HistoricalPrice> prices = <HistoricalPrice>[];
    for (int i = 0; i < result.timestamp.length; i += 1) {
      final double? closeRaw = _at(result.close, i);
      if (closeRaw == null) {
        continue;
      }
      final double close = _normalizePrice(closeRaw, rawCurrency);
      if (close <= 0) {
        continue;
      }
      prices.add(HistoricalPrice(
        symbol: symbol,
        providerSymbol: providerSymbol,
        provider: MarketDataProvider.yahoo,
        currency: currency,
        timestamp: result.timestamp[i],
        date: DateTime.fromMillisecondsSinceEpoch(result.timestamp[i] * 1000, isUtc: true).toIso8601String().split("T").first,
        open: _normalizeOptionalPrice(_at(result.open, i), rawCurrency),
        high: _normalizeOptionalPrice(_at(result.high, i), rawCurrency),
        low: _normalizeOptionalPrice(_at(result.low, i), rawCurrency),
        close: close,
        adjustedClose: _normalizeOptionalPrice(_at(result.adjustedClose, i), rawCurrency),
        volume: _normalizeVolume(_at(result.volume, i)),
      ));
    }
    prices.sort((HistoricalPrice a, HistoricalPrice b) => a.timestamp.compareTo(b.timestamp));
    if (prices.isEmpty) {
      throw const YahooChartParserError("invalidPriceSeries");
    }
    return HistoricalPriceSeries(symbol: symbol, providerSymbol: providerSymbol, provider: MarketDataProvider.yahoo, currency: currency, interval: HistoricalPriceInterval.oneDay, range: HistoricalPriceRange.twoYears, prices: prices);
}

List<DividendEvent> _parseDividends(Map<String, dynamic>? dividends, String? rawCurrency) {
    if (dividends == null) {
      return const <DividendEvent>[];
    }
    final List<DividendEvent> values = <DividendEvent>[];
    for (final dynamic value in dividends.values) {
      final Map<String, dynamic> item = value as Map<String, dynamic>;
      values.add(DividendEvent(amount: _normalizePrice((item["amount"] as num).toDouble(), rawCurrency), date: item["date"] as int));
    }
    values.sort((DividendEvent a, DividendEvent b) => a.date.compareTo(b.date));
    return values;
}

({double previousClose, double change, double changePercent, double? change1m, double? change6m, double? change1y, double? change2y}) _deriveMetrics({required HistoricalPriceSeries series, required double currentPrice}) {
    final List<HistoricalPrice> prices = series.prices;
    final double latest = prices.last.close;
    final double previousClose = prices.length > 1 ? prices[prices.length - 2].close : latest;
    final double change = currentPrice - previousClose;
    final double changePercent = previousClose == 0 ? 0 : (change / previousClose) * 100;
    return (previousClose: previousClose, change: change, changePercent: changePercent, change1m: _anchorChange(prices, currentPrice, monthsAgo: 1), change6m: _anchorChange(prices, currentPrice, monthsAgo: 6), change1y: _anchorChange(prices, currentPrice, yearsAgo: 1), change2y: _anchorChange(prices, currentPrice, yearsAgo: 2));
}

double? _anchorChange(List<HistoricalPrice> prices, double currentPrice, {int? monthsAgo, int? yearsAgo}) {
    final DateTime latest = DateTime.fromMillisecondsSinceEpoch(prices.last.timestamp * 1000, isUtc: true);
    final DateTime anchor = DateTime.utc(latest.year - (yearsAgo ?? 0), latest.month - (monthsAgo ?? 0), latest.day);
    final int anchorTs = anchor.millisecondsSinceEpoch ~/ 1000;
    HistoricalPrice? base;
    for (final HistoricalPrice price in prices) {
      if (price.timestamp <= anchorTs) {
        base = price;
      }
    }
    if (base == null) {
      return null;
    }
    return base.close == 0 ? 0 : ((currentPrice - base.close) / base.close) * 100;
}

double _normalizePrice(double rawPrice, String? rawCurrency) => normalizeCurrencyAndPrice(currency: rawCurrency ?? "USD", price: rawPrice).price;

double? _normalizeOptionalPrice(double? value, String? rawCurrency) => value == null ? null : _normalizePrice(value, rawCurrency);

int? _normalizeVolume(double? value) => value == null || !value.isFinite || value < 0 ? null : value.toInt();

double _requireNum(double? value, String field) {
    if (value == null) {
      throw YahooChartParserError("missingMeta", field: field);
    }
    return value;
}

String _requireString(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      throw YahooChartParserError("missingMeta", field: field);
    }
    return value;
}

String _normalizedName(String? longName, String? shortName, String fallback) => _trimmedOrNull(longName) ?? _trimmedOrNull(shortName) ?? fallback;

String? _providerSymbolOrNull(String? raw, String normalizedSymbol) {
    final String? value = _trimmedOrNull(raw);
    return value == null || value == normalizedSymbol ? null : value;
}

String? _trimmedOrNull(String? value) {
    final String trimmed = value?.trim() ?? "";
    return trimmed.isEmpty ? null : trimmed;
}

double? _at(List<double?> values, int index) => index < values.length ? values[index] : null;
