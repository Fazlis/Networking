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
    
    public init() {}

    public func add(task: URLSessionDataTask, for id: String) async {
        if let existingTask = tasks[id] {
            print("🔁 [SessionStorage] Task already exists for id: \(id). Cancelling and replacing.")
            existingTask.cancel()
        } else {
            print("➕ [SessionStorage] Adding new task for id: \(id)")
        }

        tasks[id] = task
    }

    public func cancelTask(with id: String) async {
        if let task = tasks[id] {
            print("❌ [SessionStorage] Cancelling task for id: \(id)")
            task.cancel()
            tasks[id] = nil
        } else {
            print("⚠️ [SessionStorage] No task found to cancel for id: \(id)")
        }
    }

    public func removeTask(for id: String) async {
        if tasks.removeValue(forKey: id) != nil {
            print("🗑️ [SessionStorage] Removed task for id: \(id)")
        } else {
            print("⚠️ [SessionStorage] No task found to remove for id: \(id)")
        }
    }

    public func cancelAllTasks() async {
        print("🚨 [SessionStorage] Cancelling all tasks (\(tasks.count) total)")
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
        print("✅ [SessionStorage] All tasks cancelled and cleared")
    }
}
