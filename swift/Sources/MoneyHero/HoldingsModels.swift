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
    case gold
    case sp500
    case currencies
    case totalPortfolioBalance
    case expectedBalanceOneYear
    case expectedBalanceFiveYears
    case fetchProgress

    public var requiresHoldings: Bool {
        switch self {
        case .totalPortfolioBalance, .expectedBalanceOneYear, .expectedBalanceFiveYears:
            return true
        case .gold, .sp500, .currencies, .fetchProgress:
            return false
        }
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

    public static let `default` = CurrencyWidgetSetting(symbols: ["USD", "EUR", "GBP"])
}

public enum WidgetDefaults {
    public static let mvp: [WidgetSetting] = [
        WidgetSetting(widget: .gold, isHidden: false, order: 0),
        WidgetSetting(widget: .sp500, isHidden: false, order: 1),
        WidgetSetting(widget: .currencies, isHidden: false, order: 2),
        WidgetSetting(widget: .totalPortfolioBalance, isHidden: false, order: 3),
        WidgetSetting(widget: .expectedBalanceOneYear, isHidden: false, order: 4),
        WidgetSetting(widget: .expectedBalanceFiveYears, isHidden: false, order: 5),
        WidgetSetting(widget: .fetchProgress, isHidden: false, order: 6)
    ]
}
