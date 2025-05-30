////
//  CacheProtocol.swift
//  Core
//
//  Created by Fazliddinov Iskandar on 28/05/25.
//  
//  Email: exclusive.fazliddinov@gmail.com
//  GitHub: https://github.com/Fazlis
//  LinkedIn: https://www.linkedin.com/in/iskandar-fazliddinov-2b8438279
//  Phone: (+992) 92-100-44-55
//

import Foundation


public enum CacheProtocol: Equatable, Sendable {
    case none
    case memory(ttl: TimeInterval?)
    case disk(ttl: TimeInterval?)

    public static func == (lhs: CacheProtocol, rhs: CacheProtocol) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case (.memory, .memory): return true
        case (.disk, .disk): return true
        default: return false
        }
    }
}
