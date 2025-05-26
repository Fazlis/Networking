//
//  SimpleRetryPolicy.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation
import NetworkProtocols


public final class SimpleRetryPolicy: RetryPolicyProtocol {
    public let maxRetries: Int
    public init(maxRetries: Int = 3) {
        self.maxRetries = maxRetries
    }

    public func shouldRetry(for error: NetworkError) async -> Bool {
        switch error {
        case .noConnection, .transportError, .unknown:
            return true
        default:
            return false
        }
    }
}
