//
//  ResponseCacheProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol ResponseCachePolicyProtocol: Sendable {
    func cachedData(for key: String, cachePolicy: CacheProtocol) async -> Data?
    func etag(for key: String) async -> String?
    func store(response: HTTPURLResponse, data: Data, for key: String, policy: CacheProtocol) async
    func clear(for key: String) async
}
