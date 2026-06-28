//
//  HTTPClient.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 28/06/26.
//

import Foundation
import NetworkProtocols


public struct HTTPClient: HTTPClientProtocol {
    
    private let requestBuilder: RequestBuilderProtocol
    
    private let requestExecutor: RequestExecutorProtocol
    
    public init(
        session: URLSession = .shared,
        requestBuilder: RequestBuilderProtocol,
        requestExecutor: RequestExecutorProtocol
    ) {
        self.requestBuilder = requestBuilder
        self.requestExecutor = requestExecutor
    }
    
    public func send<E>(_ endpoint: E) async throws -> Data where E : NetworkProtocols.Endpoint {
        let request = try await requestBuilder.build(from: endpoint)
        
        let data = try await requestExecutor.execute(request)
        
        return data
    }
}
