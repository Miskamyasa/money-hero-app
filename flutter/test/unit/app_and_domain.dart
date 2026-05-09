part of "../money_hero_test.dart";

void registerAppAndDomainTests() {
  testWidgets("root app initializes", (WidgetTester tester) async {
    await tester.pumpWidget(const MoneyHeroApp());
    expect(find.text("Dashboard"), findsOneWidget);
  });

  test("symbol normalization and currency defaults", () {
    expect(normalizeSymbol(" aapl "), "AAPL");
    expect(CurrencyWidgetSetting.defaults.symbols, <String>["USD", "EUR", "GBP"]);
    expect(MarketTickerSetting.defaults.symbols, <String>["GC=F", "^GSPC"]);
  });

  test("subunit conversion", () {
    expect(normalizeCurrencyAndPrice(currency: "GBp", price: 130).price, 1.3);
  });

  test("tracked symbol dedupe", () {
    final List<String> symbols = MarketRefreshCoordinator.trackedSymbols(
      activeWidgets: <DashboardWidget>[DashboardWidget.keyMarkets, DashboardWidget.currencies],
      holdings: const <Holding>[Holding(symbol: " aapl ", shares: 1, targetWeight: null, isHidden: false), Holding(symbol: "AAPL", shares: 1, targetWeight: null, isHidden: false)],
      currencySettings: CurrencyWidgetSetting.defaults,
      marketTickerSettings: MarketTickerSetting.defaults,
    );
    expect(symbols, <String>["GC=F", "^GSPC", "USD", "EUR", "GBP", "AAPL"]);
  });
}
