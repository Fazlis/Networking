//
//  TokenRefresherProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation


public protocol TokenRefresherProtocol: Sendable {
    func refreshIfNeeded() async throws
}
