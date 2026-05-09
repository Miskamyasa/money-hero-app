import "market_provider_models.dart";

class DividendEvent {
  const DividendEvent({required this.amount, required this.date});

  final double amount;
  final int date;

  Map<String, Object?> toJson() => <String, Object?>{
        "amount": amount,
        "date": date,
      };

  factory DividendEvent.fromJson(Map<String, dynamic> json) {
    return DividendEvent(
      amount: (json["amount"] as num).toDouble(),
      date: json["date"] as int,
    );
  }
}

class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.providerSymbol,
    required this.name,
    required this.provider,
    required this.price,
    required this.previousClose,
    required this.change,
    required this.changePercent,
    required this.currency,
    required this.marketTime,
    required this.exchangeTimezoneName,
    required this.change1m,
    required this.change6m,
    required this.change1y,
    required this.change2y,
    required this.dividends,
  });

  final String symbol;
  final String? providerSymbol;
  final String name;
  final MarketDataProvider provider;
  final double price;
  final double previousClose;
  final double change;
  final double changePercent;
  final String currency;
  final int? marketTime;
  final String? exchangeTimezoneName;
  final double? change1m;
  final double? change6m;
  final double? change1y;
  final double? change2y;
  final List<DividendEvent> dividends;

  Map<String, Object?> toJson() => <String, Object?>{
        "symbol": symbol,
        "providerSymbol": providerSymbol,
        "name": name,
        "provider": provider.name,
        "price": price,
        "previousClose": previousClose,
        "change": change,
        "changePercent": changePercent,
        "currency": currency,
        "marketTime": marketTime,
        "exchangeTimezoneName": exchangeTimezoneName,
        "change1m": change1m,
        "change6m": change6m,
        "change1y": change1y,
        "change2y": change2y,
        "dividends": dividends.map((dividend) => dividend.toJson()).toList(),
      };

  factory MarketQuote.fromJson(Map<String, dynamic> json) {
    return MarketQuote(
      symbol: json["symbol"] as String,
      providerSymbol: json["providerSymbol"] as String?,
      name: json["name"] as String,
      provider: MarketDataProvider.values.firstWhere(
        (provider) => provider.name == json["provider"],
      ),
      price: (json["price"] as num).toDouble(),
      previousClose: (json["previousClose"] as num).toDouble(),
      change: (json["change"] as num).toDouble(),
      changePercent: (json["changePercent"] as num).toDouble(),
      currency: json["currency"] as String,
      marketTime: json["marketTime"] as int?,
      exchangeTimezoneName: json["exchangeTimezoneName"] as String?,
      change1m: (json["change1m"] as num?)?.toDouble(),
      change6m: (json["change6m"] as num?)?.toDouble(),
      change1y: (json["change1y"] as num?)?.toDouble(),
      change2y: (json["change2y"] as num?)?.toDouble(),
      dividends: (json["dividends"] as List<dynamic>)
          .map((item) => DividendEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
