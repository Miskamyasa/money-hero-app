import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

import "../domain/market_normalization.dart";
import "market_data_protocols.dart";

class YahooFinanceClientError implements Exception {
  const YahooFinanceClientError(this.code);

  final String code;
}

class YahooFinanceClient implements MarketDataProviding {
  YahooFinanceClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static const String sp500Symbol = "^GSPC";
  static const String goldSymbol = "GC=F";

  static const String _userAgent =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile Safari/604.1";
  static const Duration _sessionTtl = Duration(minutes: 30);

  final http.Client _httpClient;
  _YahooSession? _session;

  @override
  Future<YahooHttpResponse> fetchStockChart({required String symbol}) async {
    final String normalized = normalizeSymbol(symbol);
    _YahooSession session = await _ensureSession();
    YahooHttpResponse first = await _fetchStockChartWithSession(symbol: normalized, session: session);
    if (first.statusCode == 401 || first.statusCode == 403) {
      _session = null;
      session = await _ensureSession(forceRemint: true);
      final YahooHttpResponse retry = await _fetchStockChartWithSession(symbol: normalized, session: session);
      if (retry.statusCode == 401 || retry.statusCode == 403) {
        throw const YahooFinanceClientError("stockChartUnauthorized");
      }
      _validateStatusCode(retry);
      return retry;
    }
    _validateStatusCode(first);
    return first;
  }

  @override
  Future<YahooHttpResponse> fetchCurrencyChart({required String displayedCurrency}) async {
    final String currency = normalizeCurrencyCode(displayedCurrency);
    final Uri url = Uri.https(
      "query1.finance.yahoo.com",
      "/v8/finance/chart/${currency}USD=X",
      <String, String>{"range": "2d", "interval": "1d"},
    );
    final YahooHttpResponse response = await _performRequest(url: url, includeUserAgent: true);
    _validateStatusCode(response);
    return response;
  }

  @override
  Future<YahooHttpResponse> fetchGoldQuoteChart() async {
    final Uri url = Uri.https(
      "query1.finance.yahoo.com",
      "/v8/finance/chart/$goldSymbol",
      <String, String>{"range": "1d", "interval": "1d"},
    );
    final YahooHttpResponse response = await _performRequest(url: url, includeUserAgent: true);
    _validateStatusCode(response);
    return response;
  }

  @override
  Future<YahooHttpResponse> fetchGoldHistoryChart() async {
    final ({int period1, int period2}) range = _stockPeriodRange();
    final Uri url = Uri.https(
      "query1.finance.yahoo.com",
      "/v8/finance/chart/$goldSymbol",
      <String, String>{"period1": "${range.period1}", "period2": "${range.period2}", "interval": "1d"},
    );
    final YahooHttpResponse response = await _performRequest(url: url, includeUserAgent: true);
    _validateStatusCode(response);
    return response;
  }

  Future<YahooHttpResponse> _fetchStockChartWithSession({required String symbol, required _YahooSession session}) {
    final ({int period1, int period2}) range = _stockPeriodRange();
    final Uri url = Uri.https("query1.finance.yahoo.com", "/v8/finance/chart/$symbol", <String, String>{
      "period1": "${range.period1}",
      "period2": "${range.period2}",
      "interval": "1d",
      "events": "div",
      "crumb": session.crumb,
    });
    return _performRequest(url: url, includeUserAgent: true, cookieHeader: session.cookieHeader);
  }

  Future<_YahooSession> _ensureSession({bool forceRemint = false}) async {
    if (!forceRemint && _session != null && _session!.expiresAt.isAfter(DateTime.now())) {
      return _session!;
    }
    final String cookie = await _mintCookieHeader();
    final String crumb = await _mintCrumb(cookieHeader: cookie);
    final _YahooSession session = _YahooSession(
      cookieHeader: cookie,
      crumb: crumb,
      expiresAt: DateTime.now().add(_sessionTtl),
    );
    _session = session;
    return session;
  }

  Future<String> _mintCookieHeader() async {
    final http.Request request = http.Request("GET", Uri.parse("https://fc.yahoo.com/"));
    request.followRedirects = false;
    request.maxRedirects = 0;
    final http.StreamedResponse response = await _httpClient.send(request);
    final List<String> setCookies = response.headers.entries
        .where((MapEntry<String, String> entry) => entry.key.toLowerCase() == "set-cookie")
        .map((MapEntry<String, String> entry) => entry.value)
        .toList();
    final List<String> values = setCookies
        .map((String cookie) => cookie.split(";").first.trim())
        .where((String cookie) => cookie.isNotEmpty)
        .toList();
    if (values.isEmpty) {
      throw const YahooFinanceClientError("missingSeedCookies");
    }
    return values.join("; ");
  }

  Future<String> _mintCrumb({required String cookieHeader}) async {
    final Uri url = Uri.parse("https://query2.finance.yahoo.com/v1/test/getcrumb");
    final YahooHttpResponse response = await _performRequest(
      url: url,
      includeUserAgent: true,
      cookieHeader: cookieHeader,
    );
    _validateStatusCode(response);
    final String crumb = utf8.decode(response.data).trim();
    if (crumb.isEmpty || crumb == "null") {
      throw const YahooFinanceClientError("invalidCrumb");
    }
    return crumb;
  }

  Future<YahooHttpResponse> _performRequest({required Uri url, required bool includeUserAgent, String? cookieHeader}) async {
    final Map<String, String> headers = <String, String>{};
    if (includeUserAgent) {
      headers["User-Agent"] = _userAgent;
    }
    if (cookieHeader != null) {
      headers["Cookie"] = cookieHeader;
    }
    final http.Response response = await _httpClient.get(url, headers: headers);
    return YahooHttpResponse(requestUrl: url, statusCode: response.statusCode, data: response.bodyBytes);
  }

  void _validateStatusCode(YahooHttpResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw YahooFinanceClientError("unexpectedStatus:${response.statusCode}");
    }
  }

  ({int period1, int period2}) _stockPeriodRange() {
    final int period2 = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const int twoYearsAndPaddingDays = 744 * 24 * 60 * 60;
    return (period1: period2 - twoYearsAndPaddingDays, period2: period2);
  }
}

class _YahooSession {
  const _YahooSession({required this.cookieHeader, required this.crumb, required this.expiresAt});

  final String cookieHeader;
  final String crumb;
  final DateTime expiresAt;
}
