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
        
        safePrint("🧱 [FailureStorage] Добавлен запрос в очередь повторов: \(E.self)")
        
        pendingRequests.append(operation)
    }

    public func retryAll() async {
        let tasks = pendingRequests
        pendingRequests.removeAll()
        
        safePrint("🔁 [FailureStorage] Начинаем повтор \(tasks.count) запросов")
        
        for (index, task) in tasks.enumerated() {
            do {
                safePrint("🚀 [FailureStorage] Повтор запроса \(index + 1)...")
                
                try await task()
                
                safePrint("✅ [FailureStorage] Запрос \(index + 1) успешно выполнен")
            } catch {
                safePrint("❌ [FailureStorage] Ошибка при повторе запроса \(index + 1): \(error)")
            }
        }
    }
    
    private func safePrint(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}
