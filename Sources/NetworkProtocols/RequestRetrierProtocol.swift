//
//  RequestRetrierProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 31/05/25.
//

import Foundation


public protocol RequestRetrierProtocol: Sendable {
    func executeWithRetry<T: Endpoint>(
        _ request: T,
        configuration: RetryConfiguration,
        executor: @Sendable (T) async throws -> T.Response
    ) async throws -> T.Response
}
