//
//  FailureRequestActorStorage.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation
import NetworkProtocols


public actor DefaultFailureRequestActorStorage: FailureRequestStorageProtocol {
    
    public init() {}
    
    private var pendingRequests: [@Sendable () async throws -> Void] = []

    public func pending() async -> [@Sendable () async throws -> Void] {
            pendingRequests
        }

    public func add<E>(_ request: E, using client: any AsyncRequestExecuteProtocol) async where E: Endpoint {
        let operation: @Sendable () async throws -> Void = {
            _ = try await client.execute(request)
        }
        pendingRequests.append(operation)
    }

    public func retryAll() async {
        let tasks = pendingRequests
        pendingRequests.removeAll()

        for task in tasks {
            do {
                try await task()
            } catch {
                print("Retry failed: \(error)")
            }
        }
    }
}
