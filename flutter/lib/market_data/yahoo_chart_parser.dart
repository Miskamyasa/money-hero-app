import "dart:convert";
import "dart:typed_data";

import "../domain/market_history_models.dart";
import "../domain/market_normalization.dart";
import "../domain/market_provider_models.dart";
import "../domain/market_quote_models.dart";
import "market_data_protocols.dart";
import "yahoo_finance_client.dart";

part "yahoo_chart_parser_support.dart";
part "yahoo_chart_payload.dart";

class YahooChartParserError implements Exception {
  const YahooChartParserError(this.code, {this.field});

  final String code;
  final String? field;
}

class YahooChartParser implements MarketChartParser {
  @override
  ({HistoricalPriceSeries history, MarketQuote quote}) parseStockQuoteAndHistory({required Uint8List data, required String requestedSymbol}) {
    final _YahooResult result = _firstResult(data);
    final String symbol = normalizeSymbol(requestedSymbol);
    final String? providerSymbol = _providerSymbolOrNull(result.meta.symbol, symbol);
    final HistoricalPriceSeries series = _buildSeries(symbol: symbol, providerSymbol: providerSymbol, result: result);
    final double currentPrice = _normalizePrice(_requireNum(result.meta.regularMarketPrice, "regularMarketPrice"), result.meta.currency);
    final ({double previousClose, double change, double changePercent, double? change1m, double? change6m, double? change1y, double? change2y}) metrics =
        _deriveMetrics(series: series, currentPrice: currentPrice);
    return (
      quote: MarketQuote(
        symbol: symbol,
        providerSymbol: providerSymbol,
        name: _normalizedName(result.meta.longName, result.meta.shortName, symbol),
        provider: MarketDataProvider.yahoo,
        price: currentPrice,
        previousClose: metrics.previousClose,
        change: metrics.change,
        changePercent: metrics.changePercent,
        currency: series.currency,
        marketTime: result.meta.regularMarketTime,
        exchangeTimezoneName: _trimmedOrNull(result.meta.exchangeTimezoneName),
        change1m: metrics.change1m,
        change6m: metrics.change6m,
        change1y: metrics.change1y,
        change2y: metrics.change2y,
        dividends: _parseDividends(result.eventsDividends, result.meta.currency),
      ),
      history: series,
    );
  }

  @override
  MarketQuote parseCurrencyQuote({required Uint8List data, required String requestedSymbol, required String displayedCurrency, required bool invertForUsdDisplay}) {
    final _YahooResult result = _firstResult(data);
    final String symbol = normalizeSymbol(requestedSymbol);
    final double rawPrice = _requireNum(result.meta.regularMarketPrice, "regularMarketPrice");
    final double rawPreviousClose = _requireNum(result.meta.chartPreviousClose, "chartPreviousClose");
    final double price = invertForUsdDisplay ? (1 / rawPrice) : rawPrice;
    final double previousClose = invertForUsdDisplay ? (1 / rawPreviousClose) : rawPreviousClose;
    final double change = price - previousClose;
    final double changePercent = previousClose == 0 ? 0 : (change / previousClose) * 100;
    return MarketQuote(
      symbol: symbol,
      providerSymbol: _providerSymbolOrNull(result.meta.symbol, symbol),
      name: symbol,
      provider: MarketDataProvider.yahoo,
      price: price,
      previousClose: previousClose,
      change: change,
      changePercent: changePercent,
      currency: normalizeCurrencyCode(displayedCurrency),
      marketTime: result.meta.regularMarketTime,
      exchangeTimezoneName: _trimmedOrNull(result.meta.exchangeTimezoneName),
      change1m: null,
      change6m: null,
      change1y: null,
      change2y: null,
      dividends: const <DividendEvent>[],
    );
  }

  @override
  ({HistoricalPriceSeries history, MarketQuote quote}) parseGoldQuoteAndHistory({required Uint8List quoteData, required Uint8List historyData}) {
    final _YahooResult quoteResult = _firstResult(quoteData);
    final _YahooResult historyResult = _firstResult(historyData);
    final String symbol = normalizeSymbol(YahooFinanceClient.goldSymbol);
    final String? providerSymbol = _providerSymbolOrNull(historyResult.meta.symbol, symbol);
    final HistoricalPriceSeries series = _buildSeries(symbol: symbol, providerSymbol: providerSymbol, result: historyResult);
    final double price = _normalizePrice(_requireNum(quoteResult.meta.regularMarketPrice, "regularMarketPrice"), historyResult.meta.currency);
    final ({double previousClose, double change, double changePercent, double? change1m, double? change6m, double? change1y, double? change2y}) metrics =
        _deriveMetrics(series: series, currentPrice: price);
    return (
      quote: MarketQuote(
        symbol: symbol,
        providerSymbol: providerSymbol,
        name: symbol,
        provider: MarketDataProvider.yahoo,
        price: price,
        previousClose: metrics.previousClose,
        change: metrics.change,
        changePercent: metrics.changePercent,
        currency: series.currency,
        marketTime: quoteResult.meta.regularMarketTime,
        exchangeTimezoneName: _trimmedOrNull(quoteResult.meta.exchangeTimezoneName),
        change1m: metrics.change1m,
        change6m: metrics.change6m,
        change1y: metrics.change1y,
        change2y: metrics.change2y,
        dividends: const <DividendEvent>[],
      ),
      history: series,
    );
  }
}
