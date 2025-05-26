//
//  TokenRefresher.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 26/05/25.
//

import Foundation
import NetworkProtocols


public actor TokenRefresher: TokenRefresherProtocol {
    private var isRefreshing = false

    public init() {}

    public func refreshIfNeeded() async throws {
        guard !isRefreshing else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        let refreshURL = URL(string: "https://api.example.com/refresh")!
        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refreshToken": "stored-refresh-token"])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1, data)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Для доступа к TokenStorage можно использовать actor или другую защиту
        await TokenStorage.shared.updateTokens(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String
    }
}


public actor TokenStorage {
    public static let shared = TokenStorage()

    private(set) var accessToken: String = ""
    private(set) var refreshToken: String = ""

    public func updateTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
