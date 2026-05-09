import Testing
@testable import MoneyHero

@Test func normalizeSymbolTrimsAndUppercases() throws {
    let symbol = try normalizeSymbol("  aapl  ")
    #expect(symbol == "AAPL")
}

@Test func normalizeCurrencyAndPriceConvertsSubunits() throws {
    let gbp = try normalizeCurrencyAndPrice(currency: "GBp", price: 123.0)
    #expect(gbp.currency == "GBP")
    #expect(gbp.price == 1.23)

    let ils = try normalizeCurrencyAndPrice(currency: "ILA", price: 455.0)
    #expect(ils.currency == "ILS")
    #expect(ils.price == 4.55)
}
