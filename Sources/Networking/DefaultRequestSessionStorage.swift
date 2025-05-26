//
//  RequestSessionStorage.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation
import NetworkProtocols


import Foundation

public actor DefaultRequestSessionStorage: RequestSessionStorageProtocol {
    
    private var tasks: [String: URLSessionDataTask] = [:]
    
    public init() {}

    /// Добавление задачи с учётом предыдущих
    public func add(task: URLSessionDataTask, for id: String) async {
        if let existingTask = tasks[id] {
            print("♻️ Заменяем существующий task с id: \(id). Отмена старого.")
            existingTask.cancel()
        } else {
            print("🆕 Добавляем новый task с id: \(id)")
        }

        tasks[id] = task
    }

    /// Отмена задачи по id
    public func cancelTask(with id: String) async {
        guard let task = tasks[id] else {
            print("⚠️ Нет задачи с id: \(id) для отмены")
            return
        }

        print("❌ Отменён task с id: \(id)")
        task.cancel()
        tasks[id] = nil
    }

    /// Удаление задачи после завершения или отмены
    public func removeTask(for id: String) async {
        if tasks.removeValue(forKey: id) != nil {
            print("🧹 Удалён task с id: \(id) после выполнения")
        } else {
            print("⚠️ Попытка удалить несуществующий task с id: \(id)")
        }
    }

    /// Отмена всех задач
    public func cancelAllTasks() async {
        tasks.forEach { key, task in
            print("❌ Отменён task с id: \(key)")
            task.cancel()
        }
        tasks.removeAll()
        print("🧼 Все задачи отменены и очищены")
    }
}
