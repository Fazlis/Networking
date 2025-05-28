//
//  Endpoint.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//


import Foundation


public protocol Endpoint: Sendable {
    associatedtype Response: Codable & Sendable
    var id: String { get }
    var request: URLRequest { get }
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
    var body: Data? { get }
}
