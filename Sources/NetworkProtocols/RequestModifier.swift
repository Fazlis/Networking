//
//  RequestModifier.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 28/06/26.
//

import Foundation


public protocol RequestModifier: Sendable {
    func modify(_ request: inout URLRequest) async throws
}
