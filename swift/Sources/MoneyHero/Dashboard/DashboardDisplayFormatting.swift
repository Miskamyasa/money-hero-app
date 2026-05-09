import Foundation
import SwiftUI

enum MarketDataDisplayState: Equatable {
    case loading
    case error
    case noData
    case ready
}

func formatPercent(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(String(format: "%.2f", value))%"
}

func formatPrice(_ value: Double, currency: String) -> String {
    if currency == "USD" {
        return "$\(String(format: "%.2f", value))"
    }

    return "\(currency) \(String(format: "%.2f", value))"
}

func normalizedDashboardSymbol(_ symbol: String) -> String {
    (try? normalizeSymbol(symbol)) ?? symbol
}

func marketTitle(symbol: String, quote: CachedMarketQuote?) -> String {
    let normalized = normalizedDashboardSymbol(symbol)

    if normalized == "GC=F" {
        return "Gold"
    }
    if normalized == "^GSPC" {
        return "S&P 500"
    }

    return quote?.data.name ?? normalized
}

func lastUpdatedText(timestampMs: Int?) -> String {
    guard let timestampMs else {
        return "No market data yet"
    }

    let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000)
    return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
}

func displayState(quote: CachedMarketQuote?, isLoading: Bool) -> MarketDataDisplayState {
    if let quote, quote.metadata.status == .error {
        return .error
    }
    if quote != nil {
        return .ready
    }
    return isLoading ? .loading : .noData
}

func fallbackChange(for symbol: String) -> Double {
    switch symbol {
    case "GC=F", "^GSPC", "^TA125.TA":
        return 1
    default:
        return -1
    }
}

func fallbackSparklineValues(for symbol: String) -> [Double] {
    switch symbol {
    case "GC=F":
        return [11, 13, 14, 13, 16, 15, 18, 17, 16, 17, 18, 17, 19, 18, 17]
    case "^GSPC":
        return [10, 11, 13, 12, 14, 15, 17, 15, 16, 15, 16, 17, 16, 17, 18]
    case "^TA125.TA":
        return [9, 10, 11, 10, 13, 14, 16, 15, 17, 20, 18, 16, 17, 16, 19]
    default:
        return [18, 17, 16, 17, 15, 14, 16, 13, 12, 12, 11, 10, 11, 9, 8]
    }
}
