//
//  RequestErrorHandlerProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol RequestErrorHandlerProtocol: Sendable {
    func handle<E: Endpoint>(error: Error, for endpoint: E, using client: AsyncRequestExecuteProtocol) async throws -> E.Response
}
