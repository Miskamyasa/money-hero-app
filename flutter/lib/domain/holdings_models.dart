class Holding {
  const Holding({
    required this.symbol,
    required this.shares,
    required this.targetWeight,
    required this.isHidden,
  });

  final String symbol;
  final double shares;
  final double? targetWeight;
  final bool isHidden;
}

enum DashboardWidget {
  currencies,
  keyMarkets,
  fetchProgress,
}

extension DashboardWidgetRules on DashboardWidget {
  bool get requiresHoldings => false;
}

class WidgetSetting {
  const WidgetSetting({
    required this.widget,
    required this.isHidden,
    required this.order,
  });

  final DashboardWidget widget;
  final bool isHidden;
  final int order;
}

class CurrencyWidgetSetting {
  const CurrencyWidgetSetting({required this.symbols});

  final List<String> symbols;

  static const CurrencyWidgetSetting defaults =
      CurrencyWidgetSetting(symbols: <String>["USD", "EUR", "GBP"]);
}

class MarketTickerSetting {
  const MarketTickerSetting({required this.symbols});

  final List<String> symbols;

  static const MarketTickerSetting defaults =
      MarketTickerSetting(symbols: <String>["GC=F", "^GSPC"]);
}

class WidgetDefaults {
  static const List<WidgetSetting> mvp = <WidgetSetting>[
    WidgetSetting(widget: DashboardWidget.currencies, isHidden: false, order: 0),
    WidgetSetting(widget: DashboardWidget.keyMarkets, isHidden: false, order: 1),
    WidgetSetting(widget: DashboardWidget.fetchProgress, isHidden: false, order: 2),
  ];
}
