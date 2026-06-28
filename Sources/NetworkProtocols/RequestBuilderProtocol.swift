//
//  RequestBuilderProtocol.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 28/06/26.
//


import Foundation


public protocol RequestBuilderProtocol {
    func build<E: Endpoint>(from endpoint: E) async throws -> URLRequest
}
