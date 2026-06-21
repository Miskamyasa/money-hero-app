class MarketNormalizationException implements Exception {
  const MarketNormalizationException(this.code, {this.field});

  final String code;
  final String? field;
}

String normalizeSymbol(String rawSymbol) {
  final String symbol = rawSymbol.trim().toUpperCase();
  if (symbol.isEmpty || symbol.length > 32) {
    throw const MarketNormalizationException("invalidSymbol");
  }
  return symbol;
}

String normalizeCurrencyCode(String rawCurrency) {
  final String currency = rawCurrency.trim().toUpperCase();
  if (currency.length < 3 || currency.length > 8) {
    throw const MarketNormalizationException("invalidCurrency");
  }
  return currency;
}

({String currency, double price}) normalizeCurrencyAndPrice({
  required String currency,
  required double price,
}) {
  validateFiniteNumber(price, field: "price");
  final String trimmed = currency.trim();
  if (trimmed == "GBp") {
    return (currency: "GBP", price: price / 100);
  }
  if (trimmed == "ILA") {
    return (currency: "ILS", price: price / 100);
  }
  return (currency: normalizeCurrencyCode(trimmed), price: price);
}

void validateFiniteNumber(double value, {required String field}) {
  if (!value.isFinite) {
    throw MarketNormalizationException("nonFiniteNumber", field: field);
  }
}
