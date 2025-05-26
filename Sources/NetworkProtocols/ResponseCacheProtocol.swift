//
//  ResponseCacheProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol ResponseCacheProtocol: Sendable {
    var etagList: [String: String] { get }
    var cahcedResponsList: [String: Data] { get }
    func setETag(_ etag: String, forKey key: String)
    func setCachedResponse(_ data: Data, forKey key: String)
    func getETag(forKey key: String) -> String?
    func getCachedResponse(forKey key: String) -> Data?
    func removeAllData()
}
