//
//  RequestSessionStorage.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation
import NetworkProtocols


public actor DefaultRequestSessionStorage: RequestSessionStorageProtocol {
    
    private var tasks: [String: URLSessionDataTask] = [:]
    
    private var isDebug: Bool
    
    public init(isDebug: Bool = false) {
        self.isDebug = isDebug
    }

    /// Добавление задачи с учётом предыдущих
    public func add(task: URLSessionDataTask, for id: String) async {
        if let existingTask = tasks[id] {
            safePrint(isDebug: self.isDebug, "♻️ Заменяем существующий task с id: \(id). Отмена старого.")
            existingTask.cancel()
        } else {
            safePrint(isDebug: self.isDebug, "🆕 Добавляем новый task с id: \(id)")
        }

        tasks[id] = task
    }

    /// Отмена задачи по id
    public func cancelTask(with id: String) async {
        guard let task = tasks[id] else {
            safePrint(isDebug: self.isDebug, "⚠️ Нет задачи с id: \(id) для отмены")
            return
        }

        safePrint(isDebug: self.isDebug, "❌ Отменён task с id: \(id)")
        task.cancel()
        tasks[id] = nil
    }

    /// Удаление задачи после завершения или отмены
    public func removeTask(for id: String) async {
        if tasks.removeValue(forKey: id) != nil {
            safePrint(isDebug: self.isDebug, "🧹 Удалён task с id: \(id) после выполнения")
        } else {
            safePrint(isDebug: self.isDebug, "⚠️ Попытка удалить несуществующий task с id: \(id)")
        }
    }

    /// Отмена всех задач
    public func cancelAllTasks() async {
        tasks.forEach { key, task in
            safePrint(isDebug: self.isDebug, "❌ Отменён task с id: \(key)")
            task.cancel()
        }
        tasks.removeAll()
        safePrint(isDebug: self.isDebug, "🧼 Все задачи отменены и очищены")
    }
}
