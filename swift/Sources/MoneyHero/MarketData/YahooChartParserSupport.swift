import Foundation

extension YahooChartParser {
    func decodePayload(_ data: Data) throws -> YahooChartPayload {
        do {
            return try JSONDecoder().decode(YahooChartPayload.self, from: data)
        } catch {
            throw YahooChartParserError.invalidJSON
        }
    }

    func firstResult(_ payload: YahooChartPayload) throws -> YahooChartResult {
        guard let result = payload.chart.result?.first else {
            throw YahooChartParserError.missingResult
        }
        return result
    }

    func requireMeta(_ value: Double?, field: String) throws -> Double {
        guard let value else {
            throw YahooChartParserError.missingMeta(field: field)
        }
        try validateFiniteNumber(value, field: field)
        return value
    }

    func requireMeta(_ value: String?, field: String) throws -> String {
        guard let value else {
            throw YahooChartParserError.missingMeta(field: field)
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw YahooChartParserError.missingMeta(field: field)
        }
        return trimmed
    }

    func trimmedOrNil(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func normalizedName(longName: String?, shortName: String?, fallbackSymbol: String) -> String {
        if let longName = trimmedOrNil(longName) {
            return longName
        }
        if let shortName = trimmedOrNil(shortName) {
            return shortName
        }
        return fallbackSymbol
    }

    func providerSymbolOrNil(raw: String?, normalizedSymbol: String) -> String? {
        guard let raw = trimmedOrNil(raw) else {
            return nil
        }
        return raw.uppercased() == normalizedSymbol ? nil : raw
    }

    func value(at index: Int, from values: [Double?]) -> Double? {
        guard index < values.count else {
            return nil
        }
        return values[index]
    }
}
