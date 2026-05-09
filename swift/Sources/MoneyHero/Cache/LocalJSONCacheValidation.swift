import Foundation

func validateCachedMarketQuote(_ envelope: CachedMarketQuote) throws {
    try validateMetadata(envelope.metadata, expectedKind: .marketQuote)
    try validateQuote(envelope.data)
}

func validateCachedHistoricalPrices(_ envelope: CachedHistoricalPrices) throws {
    try validateMetadata(envelope.metadata, expectedKind: .historicalPrices)
    try validateHistoricalSeries(envelope.data)
}

private func validateMetadata(_ metadata: LocalCacheMetadata, expectedKind: CacheKind) throws {
    guard metadata.kind == expectedKind else {
        throw LocalJSONCacheStoreError.kindMismatch
    }

    guard !metadata.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          metadata.schemaVersion > 0,
          metadata.fetchedAt >= 0,
          metadata.staleAt >= 0,
          metadata.expiresAt >= 0,
          metadata.writtenAt >= 0,
          metadata.staleAt <= metadata.expiresAt else {
        throw LocalJSONCacheStoreError.invalidMetadata
    }
}

private func validateQuote(_ quote: MarketQuote) throws {
    _ = try normalizeSymbol(quote.symbol)
    _ = try normalizeCurrencyCode(quote.currency)

    try validateFiniteNumber(quote.price, field: "price")
    try validateFiniteNumber(quote.previousClose, field: "previousClose")
    try validateFiniteNumber(quote.change, field: "change")
    try validateFiniteNumber(quote.changePercent, field: "changePercent")

    guard quote.price > 0,
          quote.previousClose >= 0,
          !quote.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw LocalJSONCacheStoreError.invalidPayload
    }

    for dividend in quote.dividends {
        try validateFiniteNumber(dividend.amount, field: "dividend.amount")
    }

    try validateOptionalFinite(quote.change1m, field: "change1m")
    try validateOptionalFinite(quote.change6m, field: "change6m")
    try validateOptionalFinite(quote.change1y, field: "change1y")
    try validateOptionalFinite(quote.change2y, field: "change2y")
}

private func validateHistoricalSeries(_ series: HistoricalPriceSeries) throws {
    _ = try normalizeSymbol(series.symbol)
    _ = try normalizeCurrencyCode(series.currency)

    guard !series.prices.isEmpty else {
        throw LocalJSONCacheStoreError.invalidPayload
    }

    for price in series.prices {
        _ = try normalizeSymbol(price.symbol)
        _ = try normalizeCurrencyCode(price.currency)
        try validateFiniteNumber(price.close, field: "close")
        guard price.close > 0 else {
            throw LocalJSONCacheStoreError.invalidPayload
        }
        try validateOptionalFinite(price.open, field: "open")
        try validateOptionalFinite(price.high, field: "high")
        try validateOptionalFinite(price.low, field: "low")
        try validateOptionalFinite(price.adjustedClose, field: "adjustedClose")
    }
}

private func validateOptionalFinite(_ value: Double?, field: String) throws {
    guard let value else {
        return
    }
    try validateFiniteNumber(value, field: field)
}
