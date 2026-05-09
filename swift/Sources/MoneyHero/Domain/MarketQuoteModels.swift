public struct DividendEvent: Codable, Equatable, Sendable {
    public let amount: Double
    public let date: Int

    public init(amount: Double, date: Int) {
        self.amount = amount
        self.date = date
    }
}

public struct MarketQuote: Codable, Equatable, Sendable {
    public let symbol: String
    public let providerSymbol: String?
    public let name: String
    public let provider: MarketDataProvider
    public let price: Double
    public let previousClose: Double
    public let change: Double
    public let changePercent: Double
    public let currency: String
    public let marketTime: Int?
    public let exchangeTimezoneName: String?
    public let change1m: Double?
    public let change6m: Double?
    public let change1y: Double?
    public let change2y: Double?
    public let dividends: [DividendEvent]

    public init(
        symbol: String,
        providerSymbol: String?,
        name: String,
        provider: MarketDataProvider,
        price: Double,
        previousClose: Double,
        change: Double,
        changePercent: Double,
        currency: String,
        marketTime: Int?,
        exchangeTimezoneName: String?,
        change1m: Double?,
        change6m: Double?,
        change1y: Double?,
        change2y: Double?,
        dividends: [DividendEvent]
    ) {
        self.symbol = symbol
        self.providerSymbol = providerSymbol
        self.name = name
        self.provider = provider
        self.price = price
        self.previousClose = previousClose
        self.change = change
        self.changePercent = changePercent
        self.currency = currency
        self.marketTime = marketTime
        self.exchangeTimezoneName = exchangeTimezoneName
        self.change1m = change1m
        self.change6m = change6m
        self.change1y = change1y
        self.change2y = change2y
        self.dividends = dividends
    }
}
