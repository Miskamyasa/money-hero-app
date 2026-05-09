import Foundation

extension YahooChartParser {
    func normalizePrice(_ value: Double, currency: String, rawCurrency: String) throws -> Double {
        let normalized: Double
        if currency.isEmpty {
            normalized = try normalizeCurrencyAndPrice(currency: rawCurrency, price: value).price
        } else {
            let raw = rawCurrency.trimmingCharacters(in: .whitespacesAndNewlines)
            switch raw {
            case "GBp", "ILA":
                normalized = value / 100
            default:
                normalized = value
            }
        }

        try validateFiniteNumber(normalized, field: "price")
        return normalized
    }

    func normalizeOptionalPrice(_ value: Double?, currency: String, rawCurrency: String) throws -> Double? {
        guard let value else {
            return nil
        }
        return try normalizePrice(value, currency: currency, rawCurrency: rawCurrency)
    }
}
