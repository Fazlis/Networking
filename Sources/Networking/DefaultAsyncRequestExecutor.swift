//
//  AsyncRequestExecutor.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation
import NetworkProtocols


public actor DefaultAsyncRequestExecutor: AsyncRequestExecuteProtocol {
    private let logger: RequestLoggerProtocol
    private let session: URLSession = .shared
    private let responseCacher: ResponseCachePolicyProtocol
    private var isDebug: Bool

    public init(
        logger: RequestLoggerProtocol,
        responseCacher: ResponseCachePolicyProtocol,
        isDebug: Bool = false
    ) {
        self.isDebug = isDebug
        self.logger = logger
        self.responseCacher = responseCacher
    }

    public func execute<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        let start = Date()
        var request = endpoint.request
        
        logger.logRequest(request)
        
        if let cachedData = await responseCacher.cachedData(for: endpoint.id, cachePolicy: endpoint.cachePolicy) {
            safePrint(isDebug: isDebug, "📦 [RESPONSE FROM CACHE] from \(endpoint.id)")
            do {
                return try JSONDecoder().decode(E.Response.self, from: cachedData)
            } catch {
                safePrint(isDebug: isDebug, "⚠️ Cached data corrupted or decoding failed: \(error)")
                throw NetworkError.decodingError(error)
            }
        }
        
        if let etag = await responseCacher.etag(for: endpoint.id),
           endpoint.cachePolicy != .none {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response): (Data, URLResponse)
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                logger.logResponse(nil, request, data: nil, error: error, duration: Date().timeIntervalSince(start))
                throw NetworkError.noConnection
            } else {
                logger.logResponse(nil, request, data: nil, error: error, duration: Date().timeIntervalSince(start))
                throw NetworkError.transportError(error)
            }
        }

        logger.logResponse(response, request, data: data, error: nil, duration: Date().timeIntervalSince(start))

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.logResponse(response, request, data: data, error: NetworkError.unknown, duration: Date().timeIntervalSince(start))
            throw NetworkError.unknown
        }
        
        if httpResponse.statusCode == 304 {
            if let cached = await responseCacher.cachedData(for: endpoint.id, cachePolicy: endpoint.cachePolicy) {
                return try JSONDecoder().decode(E.Response.self, from: cached)
            } else {
                throw NetworkError.noCache
            }
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            logger.logResponse(
                response,
                request,
                data: data,
                error: NetworkError.httpError(httpResponse.statusCode, data),
                duration: Date().timeIntervalSince(start)
            )
            throw NetworkError.httpError(httpResponse.statusCode, data)
        }
        
        let cacheControlInstruction = httpResponse.value(forHTTPHeaderField: "Cache-Control") ?? ""
        
        if !(cacheControlInstruction.contains("no-store") || cacheControlInstruction.contains("no-cache")) {
            let overrideTTL = extractMaxAge(from: cacheControlInstruction)
            
            let cachePolicy = cacheControlInstruction.isEmpty ? endpoint.cachePolicy : .disk(ttl: overrideTTL)
            
            await responseCacher.store(
                response: httpResponse,
                data: data,
                for: endpoint.id,
                policy: cachePolicy
            )
        }

        do {
            return try JSONDecoder().decode(E.Response.self, from: data)
        } catch {
            logger.logResponse(
                response,
                request,
                data: data,
                error: NetworkError.decodingError(error),
                duration: Date().timeIntervalSince(start)
            )
            throw NetworkError.decodingError(error)
        }
    }
    
    func extractMaxAge(from header: String) -> TimeInterval? {
        let components = header.components(separatedBy: ",")
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.starts(with: "max-age="),
               let secondsString = trimmed.components(separatedBy: "=").last,
               let seconds = TimeInterval(secondsString) {
                return seconds
            }
        }
        return nil
    }
}
