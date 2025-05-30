//
//  FailureRequestActorStorage.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation
import NetworkProtocols


public actor DefaultFailureRequestActorStorage: ContinuableFailureRequestStorageProtocol {
    
    private var isDebug: Bool
    
    public init(isDebug: Bool = false) {
        self.isDebug = isDebug
    }
    
    private struct DeferredRequest {
        let operation: @Sendable () async throws -> Void
        let continuation: CheckedContinuation<Void, Error>?
    }
    
    private var pendingRequests: [DeferredRequest] = []
    
    public func pending() async -> [@Sendable () async throws -> Void] {
        safePrint(isDebug: self.isDebug, "📋 Получение списка отложенных запросов, всего: \(pendingRequests.count)")
        return pendingRequests.map { $0.operation }
    }

    public func add<E: Endpoint>(
            _ request: E,
            using client: AsyncRequestExecuteProtocol
        ) async {
            await add(request, using: client, continuation: nil)
        }

        // Новый метод — с continuation
        public func add<E: Endpoint>(
            _ request: E,
            using client: AsyncRequestExecuteProtocol,
            continuation: CheckedContinuation<E.Response, Error>? = nil
        ) async {
            safePrint(isDebug: self.isDebug, "➕ Добавляем новый отложенный запрос с id: \(request.id)")

            let operation: @Sendable () async throws -> Void = {
                await safePrint(isDebug: self.isDebug, "▶️ Выполняем отложенный запрос с id: \(request.id)")
                do {
                    let response = try await client.execute(request)
                    await safePrint(isDebug: self.isDebug, "✅ Успешно выполнен отложенный запрос с id: \(request.id)")
                    continuation?.resume(returning: response)
                } catch {
                    await safePrint(isDebug: self.isDebug, "❌ Ошибка при повторе запроса: \(error)")
                    continuation?.resume(throwing: error)
                }
            }

            pendingRequests.append(.init(operation: operation, continuation: nil))
        }

    public func retryAll() async {
        let tasks = pendingRequests
        pendingRequests.removeAll()
        safePrint(isDebug: self.isDebug, "🔄 Запускаем повтор выполнения \(tasks.count) отложенных запросов...")

        for task in tasks {
            do {
                try await task.operation()
            } catch {
                safePrint(isDebug: self.isDebug, "❌ Ошибка при повторе запроса: \(error)")
            }
        }

        safePrint(isDebug: self.isDebug, "🎉 Все отложенные запросы обработаны")
    }
}
