//
//  DefaultRetryDecision.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 31/05/25.
//

import Foundation
import NetworkProtocols


public final class DefaultRetryDecision: RetryDecisionProtocol {
    public init() {}
    
    public func shouldRetry(error: Error, attemptNumber: Int, configuration: RetryConfiguration) -> Bool {
        
        guard attemptNumber < configuration.maxRetries else {
            return false
        }
        
        switch error {
        case NetworkError.httpError(let code, _):
            return shouldRetryForHTTPCode(code)
            
        case URLError.timedOut,
             URLError.networkConnectionLost,
             URLError.notConnectedToInternet,
             URLError.cannotConnectToHost,
             URLError.cannotFindHost,
             URLError.dnsLookupFailed:
            return true
            
        case NetworkError.noConnection:
            return true
            
        case NetworkError.decodingError:
            return false // Don't retry parsing errors
            
        case NetworkError.invalidURL:
            return false // Don't retry invalid URLs
            
        case NetworkError.unknown:
            return attemptNumber < 2 // Only retry once for unknown errors
            
        default:
            return false
        }
    }
    
    private func shouldRetryForHTTPCode(_ code: Int) -> Bool {
        switch code {
        case 408, // Request Timeout
             429, // Too Many Requests
             500, // Internal Server Error
             502, // Bad Gateway
             503, // Service Unavailable
             504: // Gateway Timeout
            return true
            
        case 400...499:
            return false
            
        default:
            return false
        }
    }
    
    public func delayForRetry(attemptNumber: Int, configuration: RetryConfiguration) -> TimeInterval {
        let exponentialDelay = configuration.baseDelay * pow(configuration.backoffMultiplier, Double(attemptNumber))
        let cappedDelay = min(exponentialDelay, configuration.maxDelay)
        
        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: configuration.jitterRange)
        return cappedDelay * jitter
    }
}
