import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct YahooSession: Sendable {
    let cookieHeader: String
    let crumb: String
    let createdAt: Date
}

extension YahooFinanceClient {
    func ensureSession(forceRemint: Bool = false) async throws -> YahooSession {
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

        let header = HTTPCookie
            .cookies(withResponseHeaderFields: responseHeaderFields(from: httpResponse), for: url)
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

    private func responseHeaderFields(from response: HTTPURLResponse) -> [String: String] {
        var headerFields: [String: String] = [:]

        for (key, value) in response.allHeaderFields {
            guard let keyString = key as? String, let valueString = value as? String else {
                continue
            }
            headerFields[keyString] = valueString
        }

        return headerFields
    }
}

final class RedirectBlockerDelegate: NSObject, URLSessionTaskDelegate {
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
