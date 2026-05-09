import Foundation
import Testing
@testable import MoneyHero

@Test func parserReturnsFailureForMissingResult() {
    let parser = YahooChartParser()
    let payload = Data("{\"chart\":{\"result\":null}}".utf8)

    #expect(throws: YahooChartParserError.missingResult) {
        try parser.parseCurrencyQuote(
            data: payload,
            requestedSymbol: "EURUSD=X",
            displayedCurrency: "EUR",
            invertForUSDDisplay: false
        )
    }
}

@Test func parserNormalizesSubunitCurrencyFromHistoryAndDividends() throws {
    let parser = YahooChartParser()
    let payload = Data(
        """
        {
          "chart": {
            "result": [
              {
                "meta": {
                  "symbol": "VOD.L",
                  "currency": "GBp",
                  "regularMarketPrice": 130,
                  "regularMarketTime": 1700000000,
                  "exchangeTimezoneName": "Europe/London",
                  "longName": "Vodafone Group"
                },
                "timestamp": [1690000000, 1700000000],
                "indicators": {
                  "quote": [
                    {
                      "open": [100, 120],
                      "high": [110, 140],
                      "low": [90, 110],
                      "close": [100, 120],
                      "volume": [1, 2]
                    }
                  ],
                  "adjclose": [
                    {
                      "adjclose": [100, 120]
                    }
                  ]
                },
                "events": {
                  "dividends": {
                    "1": {
                      "amount": 55,
                      "date": 1695000000
                    }
                  }
                }
              }
            ]
          }
        }
        """.utf8
    )

    let parsed = try parser.parseStockQuoteAndHistory(data: payload, requestedSymbol: " vod.l ")
    #expect(parsed.quote.symbol == "VOD.L")
    #expect(parsed.quote.currency == "GBP")
    #expect(parsed.quote.price == 1.3)
    #expect(parsed.quote.previousClose == 1.0)
    #expect(parsed.quote.dividends.first?.amount == 0.55)
    #expect(parsed.history.currency == "GBP")
    #expect(parsed.history.prices.count == 2)
    #expect(parsed.history.prices.last?.close == 1.2)
}
