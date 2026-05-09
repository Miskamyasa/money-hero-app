import "../domain/market_history_models.dart";
import "../domain/market_normalization.dart";
import "../domain/market_provider_models.dart";
import "../domain/market_quote_models.dart";
import "market_data_protocols.dart";
import "market_refresh_request_planner.dart";
import "yahoo_finance_client.dart";

class MarketQuoteFetchResult {
  const MarketQuoteFetchResult({required this.symbol, required this.quote, required this.history});

  final String symbol;
  final MarketQuote quote;
  final HistoricalPriceSeries? history;
}

class MarketQuoteFetcher {
  const MarketQuoteFetcher({required this.provider, required this.parser});

  final MarketDataProviding provider;
  final MarketChartParser parser;

  Future<MarketQuoteFetchResult> fetch({required String symbol, required MarketRefreshTrackedSymbolKind kind}) async {
    final String normalized = normalizeSymbol(symbol);
    if (kind == MarketRefreshTrackedSymbolKind.currency) {
      if (normalized == "USD") {
        return const MarketQuoteFetchResult(
          symbol: "USD",
          quote: MarketQuote(symbol: "USD", providerSymbol: null, name: "US Dollar", provider: MarketDataProvider.yahoo, price: 1, previousClose: 1, change: 0, changePercent: 0, currency: "USD", marketTime: null, exchangeTimezoneName: null, change1m: null, change6m: null, change1y: null, change2y: null, dividends: <DividendEvent>[]),
          history: null,
        );
      }
      final response = await provider.fetchCurrencyChart(displayedCurrency: normalized);
      final quote = parser.parseCurrencyQuote(
        data: response.data,
        requestedSymbol: normalized,
        displayedCurrency: normalized,
        invertForUsdDisplay: true,
      );
      return MarketQuoteFetchResult(symbol: normalized, quote: quote, history: null);
    }
    if (normalized == YahooFinanceClient.goldSymbol) {
      final quoteResponse = await provider.fetchGoldQuoteChart();
      final historyResponse = await provider.fetchGoldHistoryChart();
      final parsed = parser.parseGoldQuoteAndHistory(quoteData: quoteResponse.data, historyData: historyResponse.data);
      return MarketQuoteFetchResult(symbol: normalized, quote: parsed.quote, history: parsed.history);
    }
    final response = await provider.fetchStockChart(symbol: normalized);
    final parsed = parser.parseStockQuoteAndHistory(data: response.data, requestedSymbol: normalized);
    return MarketQuoteFetchResult(symbol: normalized, quote: parsed.quote, history: parsed.history);
  }

}
