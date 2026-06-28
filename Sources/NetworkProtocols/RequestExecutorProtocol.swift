//
//  RequestExecutorProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 28/06/26.
//

import Foundation


public protocol RequestExecutorProtocol {
    func execute(_ request: URLRequest) async throws -> Data
}
