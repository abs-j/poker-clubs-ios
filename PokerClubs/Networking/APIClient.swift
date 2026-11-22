import Foundation

final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    private let base = "https://pokerclubs.abhayjhade.com"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        session = URLSession(configuration: config)
    }

    // MARK: - Generic request methods

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await perform(request(path, method: "GET"))
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await perform(jsonRequest(path, method: "POST", body: body))
    }

    func postVoid<B: Encodable>(_ path: String, body: B) async throws {
        try await performVoid(jsonRequest(path, method: "POST", body: body))
    }

    func postVoid(_ path: String) async throws {
        try await performVoid(request(path, method: "POST"))
    }

    func patch<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await perform(jsonRequest(path, method: "PATCH", body: body))
    }

    func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await perform(jsonRequest(path, method: "PUT", body: body))
    }

    func delete(_ path: String) async throws {
        try await performVoid(request(path, method: "DELETE"))
    }

    func delete<B: Encodable>(_ path: String, body: B) async throws {
        try await performVoid(jsonRequest(path, method: "DELETE", body: body))
    }

    func clearCookies() {
        guard let url = URL(string: base),
              let cookies = HTTPCookieStorage.shared.cookies(for: url) else { return }
        cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }

    // MARK: - Private

    private func request(_ path: String, method: String) -> URLRequest {
        var r = URLRequest(url: URL(string: base + path)!)
        r.httpMethod = method
        r.setValue("application/json", forHTTPHeaderField: "Accept")
        return r
    }

    private func jsonRequest<B: Encodable>(_ path: String, method: String, body: B) throws -> URLRequest {
        var r = request(path, method: method)
        r.httpBody = try JSONEncoder().encode(body)
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return r
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        log(request: request, response: response, data: data)
        try validate(response: response, data: data)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    private func performVoid(_ request: URLRequest) async throws {
        let (data, response) = try await session.data(for: request)
        log(request: request, response: response, data: data)
        try validate(response: response, data: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let msg = try? JSONDecoder().decode(ErrorBody.self, from: data)
            throw APIError.httpError(http.statusCode, msg?.error ?? msg?.message)
        }
    }

    private func log(request: URLRequest, response: URLResponse, data: Data) {
        #if DEBUG
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let method = request.httpMethod ?? "?"
        let url = request.url?.path ?? "?"
        let body = String(data: data, encoding: .utf8) ?? "<binary>"
        print("[\(method) \(url)] → \(status)")
        if status >= 400 || status == 0 {
            print("  Response body: \(body)")
        }
        #endif
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int, String?)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:          return "Invalid response from server."
        case .httpError(401, _):        return "Please sign in to continue."
        case .httpError(403, _):        return "You don't have permission to do that."
        case .httpError(409, let msg):  return msg ?? "Conflict — please try again."
        case .httpError(_, let msg):    return msg ?? "Something went wrong. Please try again."
        case .decodingError:            return "Unexpected response format."
        }
    }
}

private struct ErrorBody: Decodable {
    let error: String?
    let message: String?
}
