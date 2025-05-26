//
//  AsyncRequestExecutor.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation
import NetworkProtocols


public final class DefaultAsyncRequestExecutor: AsyncRequestExecuteProtocol {
    private let logger: RequestLoggerProtocol
    private let session: URLSession = .shared

    public init(logger: RequestLoggerProtocol) {
        self.logger = logger
    }

    public func execute<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        var request = endpoint.request

        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        request.httpBody = endpoint.body

        if !endpoint.queryItems.isEmpty,
           var components = URLComponents(string: endpoint.baseURL + endpoint.path) {
            components.queryItems = endpoint.queryItems
            request.url = components.url
        }

        let start = Date()
        logger.logRequest(request)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.logResponse(nil, request, data: nil, error: error, duration: Date().timeIntervalSince(start))
            throw NetworkError.transportError(error)
        }

        logger.logResponse(response, request, data: data, error: nil, duration: Date().timeIntervalSince(start))

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(httpResponse.statusCode, data)
        }

        do {
            return try JSONDecoder().decode(E.Response.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
