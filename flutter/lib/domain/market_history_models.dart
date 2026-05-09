import "market_provider_models.dart";

enum HistoricalPriceInterval {
  oneDay("1d");

  const HistoricalPriceInterval(this.value);
  final String value;
}

enum HistoricalPriceRange {
  oneMonth("1mo"),
  sixMonths("6mo"),
  oneYear("1y"),
  twoYears("2y"),
  custom("custom");

  const HistoricalPriceRange(this.value);
  final String value;
}

class HistoricalPrice {
  const HistoricalPrice({
    required this.symbol,
    required this.providerSymbol,
    required this.provider,
    required this.currency,
    required this.timestamp,
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.adjustedClose,
    required this.volume,
  });

  final String symbol;
  final String? providerSymbol;
  final MarketDataProvider provider;
  final String currency;
  final int timestamp;
  final String date;
  final double? open;
  final double? high;
  final double? low;
  final double close;
  final double? adjustedClose;
  final int? volume;

  Map<String, Object?> toJson() => <String, Object?>{
        "symbol": symbol,
        "providerSymbol": providerSymbol,
        "provider": provider.name,
        "currency": currency,
        "timestamp": timestamp,
        "date": date,
        "open": open,
        "high": high,
        "low": low,
        "close": close,
        "adjustedClose": adjustedClose,
        "volume": volume,
      };

  factory HistoricalPrice.fromJson(Map<String, dynamic> json) {
    return HistoricalPrice(
      symbol: json["symbol"] as String,
      providerSymbol: json["providerSymbol"] as String?,
      provider: MarketDataProvider.values.firstWhere(
        (provider) => provider.name == json["provider"],
      ),
      currency: json["currency"] as String,
      timestamp: json["timestamp"] as int,
      date: json["date"] as String,
      open: (json["open"] as num?)?.toDouble(),
      high: (json["high"] as num?)?.toDouble(),
      low: (json["low"] as num?)?.toDouble(),
      close: (json["close"] as num).toDouble(),
      adjustedClose: (json["adjustedClose"] as num?)?.toDouble(),
      volume: json["volume"] as int?,
    );
  }
}

class HistoricalPriceSeries {
  const HistoricalPriceSeries({
    required this.symbol,
    required this.providerSymbol,
    required this.provider,
    required this.currency,
    required this.interval,
    required this.range,
    required this.prices,
  });

  final String symbol;
  final String? providerSymbol;
  final MarketDataProvider provider;
  final String currency;
  final HistoricalPriceInterval interval;
  final HistoricalPriceRange range;
  final List<HistoricalPrice> prices;

  Map<String, Object?> toJson() => <String, Object?>{
        "symbol": symbol,
        "providerSymbol": providerSymbol,
        "provider": provider.name,
        "currency": currency,
        "interval": interval.value,
        "range": range.value,
        "prices": prices.map((price) => price.toJson()).toList(),
      };

  factory HistoricalPriceSeries.fromJson(Map<String, dynamic> json) {
    return HistoricalPriceSeries(
      symbol: json["symbol"] as String,
      providerSymbol: json["providerSymbol"] as String?,
      provider: MarketDataProvider.values.firstWhere(
        (provider) => provider.name == json["provider"],
      ),
      currency: json["currency"] as String,
      interval: HistoricalPriceInterval.values.firstWhere(
        (interval) => interval.value == json["interval"],
      ),
      range: HistoricalPriceRange.values.firstWhere(
        (range) => range.value == json["range"],
      ),
      prices: (json["prices"] as List<dynamic>)
          .map((item) => HistoricalPrice.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
