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

    public func add(task: URLSessionDataTask, for id: String) async {
        tasks[id] = task
    }

    public func cancelTask(with id: String) async {
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    public func removeTask(for id: String) async {
        tasks.removeValue(forKey: id)
    }

    public func cancelAllTasks() async {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
