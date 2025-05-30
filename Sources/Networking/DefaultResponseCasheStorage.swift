//
//  DefaultResponseCasheStorage.swift
//  EONetworkLayer
//
//  Created by Fazliddinov Iskandar on 24/05/25.
//

import Foundation
import NetworkProtocols


private final class CacheEntry: NSObject {
    let data: Data
    let timestamp: Date

    init(data: Data, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
}

private struct DiskContainer: Codable {
    let entry: CacheEntryCodable

    init(entry: CacheEntry) {
        self.entry = CacheEntryCodable(data: entry.data, timestamp: entry.timestamp)
    }
}

private struct CacheEntryCodable: Codable {
    let data: Data
    let timestamp: Date
}

public actor DefaultResponseCacheStorage: ResponseCachePolicyProtocol {
    public static let shared = DefaultResponseCacheStorage()
    public static var debug: DefaultResponseCacheStorage { .init(isDebug: true) }
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    private var etagStorage: [String: String] = [:]
    private var isDebug: Bool

    private init(isDebug: Bool = false) {
        self.isDebug = isDebug
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cachesDirectory.appendingPathComponent("NetworkCache")
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        safePrint(isDebug: self.isDebug, "📦 [Cache] Disk cache initialized at \(diskCacheURL.path)")
    }

    public func store(response: HTTPURLResponse, data: Data, for key: String, policy: CacheProtocol) async {
        if let etag = response.allHeaderFields["Etag"] as? String {
            etagStorage[key] = etag
            safePrint(isDebug: self.isDebug, "📦 [Cache] Stored ETag for key: \(key)")
        }

        let entry = CacheEntry(data: data, timestamp: Date())
        let nsKey = NSString(string: key)

        switch policy {
        case .none:
            safePrint(isDebug: self.isDebug, "📦 [Cache] Skipping caching for key: \(key)")
            return

        case .memory:
            memoryCache.setObject(entry, forKey: nsKey)
            safePrint(isDebug: self.isDebug, "📦 [Cache] Stored in memory for key: \(key)")

        case .disk:
            storeToDisk(entry, for: key)
            safePrint(isDebug: self.isDebug, "📦 [Cache] Stored to disk for key: \(key)")
        }
    }

    public func cachedData(for key: String, cachePolicy: CacheProtocol) -> Data? {
        let nsKey = NSString(string: key)

        switch cachePolicy {
        case .none:
            safePrint(isDebug: self.isDebug, "📦 [Cache] CachePolicy.none for key: \(key)")
            return nil

        case .memory(let ttl):
            if let entry = memoryCache.object(forKey: nsKey) {
                let age = Date().timeIntervalSince(entry.timestamp)
                
                if case .memory(let ttl?) = cachePolicy, age > ttl {
                    memoryCache.removeObject(forKey: nsKey)
                    safePrint(isDebug: self.isDebug, "📦 [Cache] Memory cache expired for key: \(key)")
                    return nil
                }
                
                safePrint(isDebug: self.isDebug, "📦 [Cache] Memory cache hit for key: \(key)")
                return entry.data
                
            } else {
                safePrint(isDebug: self.isDebug, "📦 [Cache] Memory cache miss for key: \(key)")
            }

        case .disk(let ttl):
            if let data = loadFromDisk(for: key, ttl: ttl) {
                safePrint(isDebug: self.isDebug, "📦 [Cache] Disk cache hit for key: \(key)")
                return data
            } else {
                safePrint(isDebug: self.isDebug, "📦 [Cache] Disk cache miss or expired for key: \(key)")
            }
        }

        return nil
    }

    public func etag(for key: String) -> String? {
        return etagStorage[key]
    }

    public func clear(for key: String) {
        memoryCache.removeObject(forKey: NSString(string: key))
        etagStorage.removeValue(forKey: key)

        let fileURL = diskCacheURL.appendingPathComponent(key.safeFileName())
        try? fileManager.removeItem(at: fileURL)
        safePrint(isDebug: self.isDebug, "📦 [Cache] Cleared cache (memory + disk + ETag) for key: \(key)")
    }

    // MARK: - Private

    private func storeToDisk(_ entry: CacheEntry, for key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(key.safeFileName())
        let container = DiskContainer(entry: entry)

        do {
            let data = try JSONEncoder().encode(container)
            try data.write(to: fileURL)
        } catch {
            safePrint(isDebug: self.isDebug, "❌ [Cache] Failed to write disk cache for \(key): \(error)")
        }
    }

    private func loadFromDisk(for key: String, ttl: TimeInterval?) -> Data? {
        let fileURL = diskCacheURL.appendingPathComponent(key.safeFileName())

        guard let data = try? Data(contentsOf: fileURL),
              let container = try? JSONDecoder().decode(DiskContainer.self, from: data) else {
            return nil
        }

        let age = Date().timeIntervalSince(container.entry.timestamp)
        if let ttl, age > ttl {
            try? fileManager.removeItem(at: fileURL)
            safePrint(isDebug: self.isDebug, "📦 [Cache] Disk cache expired and removed for key: \(key)")
            return nil
        }

        return container.entry.data
    }
}

private extension String {
    func safeFileName() -> String {
        // Удаляет все символы кроме a-z, A-Z, 0-9, -, _
        return self.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
    }
}
