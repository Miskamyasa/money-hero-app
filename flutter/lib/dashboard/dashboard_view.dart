import "package:flutter/material.dart";

import "../domain/market_cache_models.dart";
import "dashboard_display_formatting.dart";
import "dashboard_state.dart";

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.state});

  final DashboardState state;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.refreshOnAppOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (BuildContext context, _) {
        return RefreshIndicator(
          onRefresh: widget.state.refreshOnPullToRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(children: <Widget>[
                const Text("Money Hero",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: widget.state.isRefreshing
                        ? null
                        : widget.state.refreshOnPullToRefresh,
                    icon: const Icon(Icons.refresh))
              ]),
              _sectionHeader("Currencies"),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.state.currencySettings.symbols
                    .map((String s) => _currencyCard(
                        symbol: s,
                        quote: widget.state.snapshot
                            .quotesBySymbol[normalizedDashboardSymbol(s)]))
                    .toList(),
              ),
              _sectionHeader("Total Balance"),
              _projectionCard(widget.state.hasHoldings ? "--" : "No holdings"),
              _sectionHeader("Expected Balance"),
              _projectionCard(widget.state.hasHoldings ? "--" : "No holdings"),
              _sectionHeader("Key Markets"),
              ...widget.state.marketTickerSettings.symbols.map((String symbol) {
                final String normalized = normalizedDashboardSymbol(symbol);
                return _marketCard(
                    symbol: normalized,
                    quote: widget.state.snapshot.quotesBySymbol[normalized],
                    history:
                        widget.state.snapshot.historiesBySymbol[normalized]);
              }),
              const SizedBox(height: 8),
              Text(widget.state.refreshErrorMessage != null
                  ? "Refresh issue: ${widget.state.refreshErrorMessage}"
                  : "Last updated: ${lastUpdatedText(widget.state.snapshot.lastUpdatedAtMs)}"),
              if (widget.state.snapshot.progress.totalCount > 0)
                Text(
                    "${widget.state.snapshot.progress.completedCount}/${widget.state.snapshot.progress.totalCount} ${widget.state.snapshot.progress.currentLabel ?? ""}"),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)));

  Widget _currencyCard(
      {required String symbol, required CachedMarketQuote? quote}) {
    final String normalized = normalizedDashboardSymbol(symbol);
    final bool usd = normalized == "USD";
    final MarketDataDisplayState state = usd
        ? MarketDataDisplayState.ready
        : displayState(
            quote, widget.state.isInitialLoading || widget.state.isRefreshing);
    String value = "--";
    String detail = "No data";
    if (usd) {
      value = "1.00";
      detail = "Base currency";
    } else if (state == MarketDataDisplayState.loading) {
      value = "Loading";
      detail = "Fetching";
    } else if (state == MarketDataDisplayState.ready && quote != null) {
      value = quote.data.price.toStringAsFixed(4);
      detail = formatPercent(quote.data.changePercent);
    }
    return Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
            children: <Widget>[Text(normalized), Text(value), Text(detail)]));
  }

  Widget _marketCard(
      {required String symbol,
      required CachedMarketQuote? quote,
      required CachedHistoricalPrices? history}) {
    final MarketDataDisplayState state = displayState(
        quote, widget.state.isInitialLoading || widget.state.isRefreshing);
    final String price = switch (state) {
      MarketDataDisplayState.loading => "Fetching",
      MarketDataDisplayState.error => "Error",
      MarketDataDisplayState.noData => "No data",
      MarketDataDisplayState.ready => quote == null
          ? "--"
          : formatPrice(quote.data.price, quote.data.currency)
    };
    return Card(
        child: ListTile(
            title: Text(symbol),
            subtitle: Text(price),
            trailing: Text(
                quote == null ? "" : formatPercent(quote.data.changePercent))));
  }

  Widget _projectionCard(String text) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text));
}
