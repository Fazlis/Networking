//
//  RequestSessionStorageProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol RequestSessionStorageProtocol: Sendable {
    func add(task: URLSessionDataTask, for id: String) async
    func cancelTask(with id: String) async
    func removeTask(for id: String) async
    func cancelAllTasks() async
}
