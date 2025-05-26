//
//  AsyncRequestExecuteProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol AsyncRequestExecuteProtocol: Sendable {
    func execute<E: Endpoint>(_ endpoint: E) async throws -> E.Response
}
