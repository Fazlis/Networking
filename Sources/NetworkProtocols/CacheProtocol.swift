//
//  CacheProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 28/06/26.
//

import Foundation


public protocol CacheProtocol: Sendable {
    associatedtype CacheLevel: MemoryCacheProtocol
    
    var useCache: Bool { get }
    var cacheLevel: CacheLevel { get }
}

public protocol MemoryCacheProtocol: Sendable {
    associatedtype Level: CacheLevel
    
    var timeToLive: TimeInterval? { get }
    
    var level: Level { get }
}

public protocol CacheLevel: Sendable {}
