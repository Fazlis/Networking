//
//  ContinuableFailureRequestStorageProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 30/05/25.
//


public protocol ContinuableFailureRequestStorageProtocol: FailureRequestStorageProtocol {
    func add<E: Endpoint>(
        _ request: E,
        using client: AsyncRequestExecuteProtocol,
        continuation: CheckedContinuation<E.Response, Error>?
    ) async
}