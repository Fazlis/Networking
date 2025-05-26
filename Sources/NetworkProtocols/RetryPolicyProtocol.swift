//
//  RetryPolicyProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol RetryPolicyProtocol: Sendable {
    func shouldRetry(for error: NetworkError) async -> Bool
    var maxRetries: Int { get }
}
