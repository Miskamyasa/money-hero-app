import "../domain/market_cache_models.dart";
import "../domain/market_history_models.dart";
import "../domain/market_normalization.dart";
import "../domain/market_quote_models.dart";

enum LocalJsonCacheValidationError {
  invalidMetadata,
  invalidPayload,
  kindMismatch,
}

void validateCachedMarketQuote(CachedMarketQuote envelope) {
  _validateMetadata(envelope.metadata, expectedKind: CacheKind.marketQuote);
  _validateQuote(envelope.data);
}

void validateCachedHistoricalPrices(CachedHistoricalPrices envelope) {
  _validateMetadata(envelope.metadata, expectedKind: CacheKind.historicalPrices);
  _validateHistoricalSeries(envelope.data);
}

void _validateMetadata(LocalCacheMetadata metadata, {required CacheKind expectedKind}) {
  if (metadata.kind != expectedKind) {
    throw LocalJsonCacheValidationError.kindMismatch;
  }
  final String key = metadata.key.trim();
  if (key.isEmpty ||
      metadata.schemaVersion <= 0 ||
      metadata.fetchedAt < 0 ||
      metadata.staleAt < 0 ||
      metadata.expiresAt < 0 ||
      metadata.writtenAt < 0 ||
      metadata.staleAt > metadata.expiresAt) {
    throw LocalJsonCacheValidationError.invalidMetadata;
  }
}

void _validateQuote(MarketQuote quote) {
  normalizeSymbol(quote.symbol);
  normalizeCurrencyCode(quote.currency);
  validateFiniteNumber(quote.price, field: "price");
  validateFiniteNumber(quote.previousClose, field: "previousClose");
  validateFiniteNumber(quote.change, field: "change");
  validateFiniteNumber(quote.changePercent, field: "changePercent");

  if (quote.price <= 0 || quote.previousClose < 0 || quote.name.trim().isEmpty) {
    throw LocalJsonCacheValidationError.invalidPayload;
  }

  for (final DividendEvent dividend in quote.dividends) {
    validateFiniteNumber(dividend.amount, field: "dividend.amount");
  }

  _validateOptionalFinite(quote.change1m, field: "change1m");
  _validateOptionalFinite(quote.change6m, field: "change6m");
  _validateOptionalFinite(quote.change1y, field: "change1y");
  _validateOptionalFinite(quote.change2y, field: "change2y");
}

void _validateHistoricalSeries(HistoricalPriceSeries series) {
  normalizeSymbol(series.symbol);
  normalizeCurrencyCode(series.currency);
  if (series.prices.isEmpty) {
    throw LocalJsonCacheValidationError.invalidPayload;
  }

  for (final HistoricalPrice price in series.prices) {
    normalizeSymbol(price.symbol);
    normalizeCurrencyCode(price.currency);
    validateFiniteNumber(price.close, field: "close");
    if (price.close <= 0) {
      throw LocalJsonCacheValidationError.invalidPayload;
    }
    _validateOptionalFinite(price.open, field: "open");
    _validateOptionalFinite(price.high, field: "high");
    _validateOptionalFinite(price.low, field: "low");
    _validateOptionalFinite(price.adjustedClose, field: "adjustedClose");
  }
}

void _validateOptionalFinite(double? value, {required String field}) {
  if (value == null) {
    return;
  }
  validateFiniteNumber(value, field: field);
}
