//
//  DefaultRequestRetrier.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 31/05/25.
//

import Foundation
import NetworkProtocols


public actor DefaultRequestRetrier: RequestRetrierProtocol {
    private let retryDecision: RetryDecisionProtocol
    private var isDebug: Bool
    
    public init(
        isDebug: Bool = false,
        retryDecision: RetryDecisionProtocol = DefaultRetryDecision()
    ) {
        self.isDebug = isDebug
        self.retryDecision = retryDecision
    }
    
    public func executeWithRetry<T: Endpoint>(
        _ request: T,
        configuration: RetryConfiguration = .init(),
        executor: @Sendable (T) async throws -> T.Response
    ) async throws -> T.Response {
        var lastError: Error?
        
        for attemptNumber in 0..<(configuration.maxRetries + 1) {
            do {
                if attemptNumber > 0 {
                    safePrint(isDebug: isDebug, "🔄 Попытка \(attemptNumber + 1)/\(configuration.maxRetries + 1) для запроса \(request.path)")
                }
                
                let result = try await executor(request)
                
                if attemptNumber > 0 {
                    safePrint(isDebug: isDebug, "✅ Запрос \(request.path) успешно выполнен с попытки \(attemptNumber + 1)")
                }
                
                return result
                
            } catch {
                lastError = error
                safePrint(isDebug: isDebug, "❌ Попытка \(attemptNumber + 1) для \(request.path) неуспешна: \(error.localizedDescription)")
                
                let shouldRetry = retryDecision.shouldRetry(
                    error: error,
                    attemptNumber: attemptNumber,
                    configuration: configuration
                )
                
                if !shouldRetry {
                    safePrint(isDebug: isDebug, "🛑 Не будем повторять запрос \(request.path) - ошибка не подлежит повтору")
                    throw error
                }
                
                if attemptNumber < configuration.maxRetries {
                    let delay = retryDecision.delayForRetry(
                        attemptNumber: attemptNumber,
                        configuration: configuration
                    )
                    
                    safePrint(isDebug: isDebug, "⏳ Ждем \(String(format: "%.1f", delay))с перед следующей попыткой...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // If we get here, all retries failed
        safePrint(isDebug: isDebug, "💥 Все попытки исчерпаны для запроса \(request.path)")
        throw lastError ?? NetworkError.unknown
    }
}
