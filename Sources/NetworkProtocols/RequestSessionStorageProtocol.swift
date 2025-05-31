//
//  RequestSessionStorageProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol TaskCancellableProtocol: Sendable {
    func cancelTask(with id: String) async
    func removeTask(for id: String) async
    func cancelAllTasks() async
}


public protocol TaskStorageProtocol: TaskCancellableProtocol {
    func add(task: Task<Void, Never>, id: String) async
}


public protocol RequestSessionStorageProtocol: TaskCancellableProtocol {
    func add(task: URLSessionDataTask, for id: String) async
}


