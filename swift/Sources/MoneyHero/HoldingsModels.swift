public struct Holding: Codable, Equatable, Sendable {
    public let symbol: String
    public let shares: Double
    public let targetWeight: Double?
    public let isHidden: Bool

    public init(symbol: String, shares: Double, targetWeight: Double?, isHidden: Bool) {
        self.symbol = symbol
        self.shares = shares
        self.targetWeight = targetWeight
        self.isHidden = isHidden
    }
}

public enum DashboardWidget: String, Codable, Equatable, Sendable {
    case currencies
    case keyMarkets
    case fetchProgress

    public var requiresHoldings: Bool {
        false
    }
}

public struct WidgetSetting: Codable, Equatable, Sendable {
    public let widget: DashboardWidget
    public let isHidden: Bool
    public let order: Int

    public init(widget: DashboardWidget, isHidden: Bool, order: Int) {
        self.widget = widget
        self.isHidden = isHidden
        self.order = order
    }
}

public struct CurrencyWidgetSetting: Codable, Equatable, Sendable {
    public let symbols: [String]

    public init(symbols: [String]) {
        self.symbols = symbols
    }

    public static let `default` = CurrencyWidgetSetting(symbols: ["USD", "ILS", "EUR", "RUB"])
}

public struct MarketTickerSetting: Codable, Equatable, Sendable {
    public let symbols: [String]

    public init(symbols: [String]) {
        self.symbols = symbols
    }

    public static let `default` = MarketTickerSetting(symbols: [
        "GC=F",
        "^GSPC"
    ])
}

public enum WidgetDefaults {
    public static let mvp: [WidgetSetting] = [
        WidgetSetting(widget: .currencies, isHidden: false, order: 0),
        WidgetSetting(widget: .keyMarkets, isHidden: false, order: 1),
        WidgetSetting(widget: .fetchProgress, isHidden: false, order: 2)
    ]
}
