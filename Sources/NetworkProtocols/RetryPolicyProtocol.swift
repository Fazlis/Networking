//
//  RetryPolicyProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol RetryDecisionProtocol: Sendable {
    func shouldRetry(error: Error, attemptNumber: Int, configuration: RetryConfiguration) -> Bool
    func delayForRetry(attemptNumber: Int, configuration: RetryConfiguration) -> TimeInterval
}
