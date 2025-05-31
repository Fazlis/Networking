//
//  DefaultTaskStorage.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 31/05/25.
//

import Foundation
import NetworkProtocols

public actor DefaultTaskStorage: TaskStorageProtocol {
    
    private var tasks: [String: Task<Void, Never>] = [:]
    
    private var isDebug: Bool
    
    public init(isDebug: Bool = false) {
        self.isDebug = isDebug
    }
    
    public func add(task: Task<Void, Never>, id: String) {
        if let existingTask = tasks[id] {
            log("♻️ Заменяем существующую задачу [ID: \(id)]",
                details: "Всего активных задач: \(tasks.count)")
            existingTask.cancel()
        } else {
            log("🆕📌 Добавлена задача [ID: \(id)]",
                details: "Всего активных задач: \(tasks.count)")
        }

        tasks[id] = task
    }
    
    public func removeTask(for id: String) {
        guard tasks[id] != nil else {
            log("⚠️ Попытка удалить несуществующую задачу [ID: \(id)]")
            return
        }
        
        tasks[id] = nil
        log("🗑 Удалена задача [ID: \(id)]",
            details: "Осталось задач: \(tasks.count)")
    }
    
    public func cancelAllTasks() {
        guard !tasks.isEmpty else {
            log("🔍 Нет активных задач для отмены")
            return
        }
        
        let count = tasks.count
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
        
        log("🧼 Массовая отмена задач",
            details: "Отменено задач: \(count)")
    }
    
    public func cancelTask(with id: String) {
        guard let task = tasks[id] else {
            log("⚠️ Попытка отменить несуществующую задачу [ID: \(id)]")
            return
        }
        
        task.cancel()
        tasks.removeValue(forKey: id)
        log("❌ Отменена задача [ID: \(id)]",
            details: "Осталось задач: \(tasks.count)")
    }
    
    // MARK: - Вспомогательные методы
    private func log(_ message: String, details: String? = nil) {
        let header = "🌐 [RequestQueue]"
        let fullMessage = details != nil
            ? "\(header) \(message) | \(details!)"
            : "\(header) \(message)"
        
        if self.isDebug {
            print(fullMessage)
        }
    }
}
