import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct YahooHTTPResponse: Sendable {
    public let requestURL: URL
    public let statusCode: Int
    public let data: Data

    public init(requestURL: URL, statusCode: Int, data: Data) {
        self.requestURL = requestURL
        self.statusCode = statusCode
        self.data = data
    }
}

public enum YahooFinanceClientError: Error, Sendable {
    case invalidURL(String)
    case nonHTTPResponse
    case missingSeedCookies
    case invalidCrumb
    case stockChartUnauthorized(statusCode: Int)
    case unexpectedStatusCode(statusCode: Int, url: URL)
}

public actor YahooFinanceClient {
    public static let sp500Symbol = "^GSPC"
    public static let eurUsdSymbol = "EURUSD=X"
    public static let gbpUsdSymbol = "GBPUSD=X"
    public static let goldSymbol = "GC=F"

    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile Safari/604.1"
    private let sessionTTL: TimeInterval = 30 * 60

    private let session: URLSession
    private let manualRedirectSession: URLSession
    private var yahooSession: YahooSession?

    public init(session: URLSession = .shared) {
        self.session = session

        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.manualRedirectSession = URLSession(
            configuration: configuration,
            delegate: RedirectBlockerDelegate(),
            delegateQueue: nil
        )
    }

    public func fetchSP500Chart() async throws -> YahooHTTPResponse {
        let symbol = try normalizeSymbol(Self.sp500Symbol)
        return try await fetchStockChartNormalized(symbol: symbol)
    }

    public func fetchStockChart(symbol rawSymbol: String) async throws -> YahooHTTPResponse {
        let symbol = try normalizeSymbol(rawSymbol)
        return try await fetchStockChartNormalized(symbol: symbol)
    }

    public func fetchEURUSDChart() async throws -> YahooHTTPResponse {
        try await fetchCurrencyChart(symbol: Self.eurUsdSymbol)
    }

    public func fetchGBPUSDChart() async throws -> YahooHTTPResponse {
        try await fetchCurrencyChart(symbol: Self.gbpUsdSymbol)
    }

    public func fetchGoldQuoteChart() async throws -> YahooHTTPResponse {
        var components = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(Self.goldSymbol)")
        components?.queryItems = [
            URLQueryItem(name: "range", value: "1d"),
            URLQueryItem(name: "interval", value: "1d")
        ]

        let url = try makeURL(from: components, raw: "gold quote chart")
        return try await performRequest(url: url, includeUserAgent: true)
    }

    public func fetchGoldHistoryChart() async throws -> YahooHTTPResponse {
        let range = stockPeriodRange()

        var components = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(Self.goldSymbol)")
        components?.queryItems = [
            URLQueryItem(name: "period1", value: String(range.period1)),
            URLQueryItem(name: "period2", value: String(range.period2)),
            URLQueryItem(name: "interval", value: "1d")
        ]

        let url = try makeURL(from: components, raw: "gold history chart")
        return try await performRequest(url: url, includeUserAgent: true)
    }

    private func fetchStockChartNormalized(symbol: String) async throws -> YahooHTTPResponse {
        let firstSession = try await ensureSession()
        let firstResponse = try await performStockChartRequest(symbol: symbol, yahooSession: firstSession)

        if firstResponse.statusCode == 401 || firstResponse.statusCode == 403 {
            yahooSession = nil
            let reminted = try await ensureSession(forceRemint: true)
            let retryResponse = try await performStockChartRequest(symbol: symbol, yahooSession: reminted)

            if retryResponse.statusCode == 401 || retryResponse.statusCode == 403 {
                throw YahooFinanceClientError.stockChartUnauthorized(statusCode: retryResponse.statusCode)
            }

            try validateStatusCode(retryResponse)
            return retryResponse
        }

        try validateStatusCode(firstResponse)
        return firstResponse
    }

    private func fetchCurrencyChart(symbol: String) async throws -> YahooHTTPResponse {
        var components = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)")
        components?.queryItems = [
            URLQueryItem(name: "range", value: "2d"),
            URLQueryItem(name: "interval", value: "1d")
        ]

        let url = try makeURL(from: components, raw: "currency chart")
        let response = try await performRequest(url: url, includeUserAgent: true)
        try validateStatusCode(response)
        return response
    }

    private func performStockChartRequest(symbol: String, yahooSession: YahooSession) async throws -> YahooHTTPResponse {
        let range = stockPeriodRange()

        var components = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)")
        components?.queryItems = [
            URLQueryItem(name: "period1", value: String(range.period1)),
            URLQueryItem(name: "period2", value: String(range.period2)),
            URLQueryItem(name: "interval", value: "1d"),
            URLQueryItem(name: "events", value: "div"),
            URLQueryItem(name: "crumb", value: yahooSession.crumb)
        ]

        let url = try makeURL(from: components, raw: "stock chart")
        return try await performRequest(url: url, cookieHeader: yahooSession.cookieHeader, includeUserAgent: true)
    }

    private func ensureSession(forceRemint: Bool = false) async throws -> YahooSession {
        if !forceRemint, let existing = yahooSession, Date().timeIntervalSince(existing.createdAt) < sessionTTL {
            return existing
        }

        let minted = try await mintSession()
        yahooSession = minted
        return minted
    }

    private func mintSession() async throws -> YahooSession {
        let cookieHeader = try await fetchSeedCookieHeader()
        let crumb = try await fetchCrumb(cookieHeader: cookieHeader)
        return YahooSession(cookieHeader: cookieHeader, crumb: crumb, createdAt: Date())
    }

    private func fetchSeedCookieHeader() async throws -> String {
        guard let url = URL(string: "https://fc.yahoo.com/") else {
            throw YahooFinanceClientError.invalidURL("https://fc.yahoo.com/")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (_, response) = try await manualRedirectSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooFinanceClientError.nonHTTPResponse
        }

        var headerFields: [String: String] = [:]
        for (key, value) in httpResponse.allHeaderFields {
            guard let keyString = key as? String else {
                continue
            }
            guard let valueString = value as? String else {
                continue
            }
            headerFields[keyString] = valueString
        }

        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
        let header = cookies
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: "; ")

        guard !header.isEmpty else {
            throw YahooFinanceClientError.missingSeedCookies
        }

        return header
    }

    private func fetchCrumb(cookieHeader: String) async throws -> String {
        guard let url = URL(string: "https://query2.finance.yahoo.com/v1/test/getcrumb") else {
            throw YahooFinanceClientError.invalidURL("https://query2.finance.yahoo.com/v1/test/getcrumb")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooFinanceClientError.nonHTTPResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw YahooFinanceClientError.unexpectedStatusCode(statusCode: httpResponse.statusCode, url: url)
        }

        let crumb = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !crumb.isEmpty, crumb != "null" else {
            throw YahooFinanceClientError.invalidCrumb
        }

        return crumb
    }

    private func performRequest(url: URL, cookieHeader: String? = nil, includeUserAgent: Bool) async throws -> YahooHTTPResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let cookieHeader {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        if includeUserAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooFinanceClientError.nonHTTPResponse
        }

        return YahooHTTPResponse(requestURL: url, statusCode: httpResponse.statusCode, data: data)
    }

    private func makeURL(from components: URLComponents?, raw: String) throws -> URL {
        guard let url = components?.url else {
            throw YahooFinanceClientError.invalidURL(raw)
        }

        return url
    }

    private func validateStatusCode(_ response: YahooHTTPResponse) throws {
        guard (200..<300).contains(response.statusCode) else {
            throw YahooFinanceClientError.unexpectedStatusCode(statusCode: response.statusCode, url: response.requestURL)
        }
    }

    private func stockPeriodRange(referenceDate: Date = Date()) -> (period1: Int, period2: Int) {
        let period2 = Int(referenceDate.timeIntervalSince1970)
        let twoYearsAndPaddingDays: TimeInterval = 744 * 24 * 60 * 60
        let period1 = Int(referenceDate.addingTimeInterval(-twoYearsAndPaddingDays).timeIntervalSince1970)
        return (period1: period1, period2: period2)
    }
}

private struct YahooSession: Sendable {
    let cookieHeader: String
    let crumb: String
    let createdAt: Date
}

private final class RedirectBlockerDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
