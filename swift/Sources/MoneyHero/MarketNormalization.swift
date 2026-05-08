import Foundation

public enum MarketNormalizationError: Error, Equatable, Sendable {
    case invalidSymbol
    case invalidCurrency
    case nonFiniteNumber(field: String)
}

public func normalizeSymbol(_ rawSymbol: String) throws -> String {
    let symbol = rawSymbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    guard (1...32).contains(symbol.count) else {
        throw MarketNormalizationError.invalidSymbol
    }

    return symbol
}

public func normalizeCurrencyCode(_ rawCurrency: String) throws -> String {
    let currency = rawCurrency.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !currency.isEmpty else {
        throw MarketNormalizationError.invalidCurrency
    }

    let normalized = currency.uppercased()

    guard (3...8).contains(normalized.count) else {
        throw MarketNormalizationError.invalidCurrency
    }

    return normalized
}

public func normalizeCurrencyAndPrice(currency rawCurrency: String, price: Double) throws -> (currency: String, price: Double) {
    try validateFiniteNumber(price, field: "price")

    let currency = rawCurrency.trimmingCharacters(in: .whitespacesAndNewlines)

    switch currency {
    case "GBp":
        return (currency: "GBP", price: price / 100)
    case "ILA":
        return (currency: "ILS", price: price / 100)
    default:
        return (currency: try normalizeCurrencyCode(currency), price: price)
    }
}

public func validateFiniteNumber(_ value: Double, field: String) throws {
    guard value.isFinite else {
        throw MarketNormalizationError.nonFiniteNumber(field: field)
    }
}
