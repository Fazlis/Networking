//
//  Endpoint.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 28/06/26.
//

import Foundation


public protocol Endpoint {
    associatedtype CachePolicy: CacheProtocol
    
    var id: String { get }
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var cachePolicy: CachePolicy { get }
    var timeoutInterval: TimeInterval { get }
    var requestModifiers: [RequestModifier] { get }
}

public extension Endpoint {
    var id: String { baseURL.absoluteString + path }
    var timeoutInterval: TimeInterval { 30 }
    var requestModifiers: [RequestModifier] { [] }
}
