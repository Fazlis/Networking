//
//  FailureRequestStorageProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation

public protocol FailureRequestStorageProtocol: Sendable {
    func pending() async -> [@Sendable () async throws -> Void]
    func add<E: Endpoint>(_ request: E, using client: AsyncRequestExecuteProtocol) async
    func retryAll() async
}
