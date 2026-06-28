//
//  HTTPClientProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 28/06/26.
//

import Foundation


public protocol HTTPClientProtocol {
    
    @discardableResult
    func send<E: Endpoint>(_ endpoint: E) async throws -> Data
}
