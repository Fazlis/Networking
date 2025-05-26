//
//  RequestLoggerProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol RequestLoggerProtocol: Sendable {
    func logRequest(_ request: URLRequest)
    func logResponse(
        _ response: URLResponse?,
        _ request: URLRequest?,
        data: Data?,
        error: Error?,
        duration: TimeInterval
    )
}
