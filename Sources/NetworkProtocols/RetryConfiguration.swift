//
//  RetryConfiguration.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 31/05/25.
//

import Foundation


public struct RetryConfiguration: Sendable {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let backoffMultiplier: Double
    public let jitterRange: ClosedRange<Double>
    
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 3.0,
        maxDelay: TimeInterval = 60.0,
        backoffMultiplier: Double = 2.0,
        jitterRange: ClosedRange<Double> = 0.8...1.2
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
        self.jitterRange = jitterRange
    }
}
