import Testing
@testable import MoneyHero

@Test func widgetDefaultsAndCurrencyDefaultsMatchMvpContract() {
    #expect(CurrencyWidgetSetting.default.symbols == ["USD", "EUR", "GBP"])
    #expect(MarketTickerSetting.default.symbols == [
        "GC=F",
        "^GSPC"
    ])

    let expectedOrder: [DashboardWidget] = [
        .currencies,
        .keyMarkets,
        .fetchProgress
    ]

    #expect(WidgetDefaults.mvp.map(\.widget) == expectedOrder)
    #expect(WidgetDefaults.mvp.allSatisfy { $0.isHidden == false })
    #expect(DashboardWidget.currencies.requiresHoldings == false)
    #expect(DashboardWidget.keyMarkets.requiresHoldings == false)
    #expect(DashboardWidget.fetchProgress.requiresHoldings == false)
}
