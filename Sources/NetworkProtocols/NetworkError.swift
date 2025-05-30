//
//  NetworkError.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case httpError(Int, Data?)
    case transportError(Error)
    case unknown
    case noConnection
    case noCache
}

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
            (.noData, .noData),
            (.unknown, .unknown),
            (.noConnection, .noConnection),
            (.noCache, .noCache):
            return true
            
        case let (.httpError(code1, _), .httpError(code2, _)):
            return code1 == code2
            
        case let (.decodingError(e1), .decodingError(e2)):
            return e1.localizedDescription == e2.localizedDescription
            
        case let (.transportError(e1), .transportError(e2)):
            return e1.localizedDescription == e2.localizedDescription
            
        default:
            return false
        }
    }
}
