//
//  ConsoleLogger.swift
//  EONetworkLayer
//
//  Created by Fazliddinov Iskandar on 17/05/25.
//


import Foundation
import NetworkProtocols


public struct DefaultRequestLogger: RequestLoggerProtocol {
    
    private var isEnabled: Bool

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }

        var output = "✴️⬇️ [REQUEST]\n🌐 URL: \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")"
        
        if let method = request.httpMethod {
            output += "\n🔄 METHOD: \(request.httpMethod ?? "")"
        }

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            output += "\n📬 HEADERS:\n" + headers.map { "  \($0.key): \($0.value)" }.joined(separator: "\n")
        }

        if let body = request.httpBody,
           let bodyString = prettyPrintJSON(body) {
            output += "\n📦 BODY:\n\(bodyString)"
        }

        print(output + "\n✴️⬇️")
    }
    
    public func logResponse(
        _ response: URLResponse?,
        _ request: URLRequest?,
        data: Data?,
        error: (any Error)?,
        duration: TimeInterval
    ) {
        guard isEnabled else { return }
        
        let formattedDuration = String(format: " (%.2fs)", duration)
        
        guard error == nil else {
            var output = "❌🔽"
            output += "\n💾 [RESPONSE]"
            output += "\n⏱️ REQUEST DURATION: \(formattedDuration)"
            output += "\n🌐 URL: \(request?.url?.absoluteString ?? "")"
            
            if let httpResponse = response as? HTTPURLResponse {
                output += "\n📶 STATUS CODE: \(httpResponse.statusCode)"
            }
            output += "\n⛔️ Error: \(error?.localizedDescription ?? "")"
            output += "\n❌🔼"
            print(output)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            var output = "❌🔽"
            output += "\n💾 [RESPONSE]"
            output += "\n⏱️ REQUEST DURATION: \(formattedDuration)"
            output += "\n🌐 URL: \(request?.url?.absoluteString ?? "")"
            output += "\n⛔️ ERROR: Can't cast response to HTTPURLResponse"
            output += "\n❌🔼"
            print(output)
            return
        }
        
        var statusCodeIcon = httpResponse.statusCode == 200 ? "✅" : "❌"
        
        var output = "\(statusCodeIcon)🔽"
        output += "\n💾 [RESPONSE] \(httpResponse.statusCode)"
        output += "\n⏱️ REQUEST DURATION: \(formattedDuration)"
        output += "\n🌐 URL: \(request?.url?.absoluteString ?? "")"
        output += "\n📶 STATUS CODE: \(httpResponse.statusCode)"

        if let data = data,
           let bodyString = prettyPrintJSON(data) {
            output += "\n📥 RESPONSE BODY:\n\(bodyString)"
        }

        output += "\n\(statusCodeIcon)🔼"
        print(output)
    }

    private func prettyPrintJSON(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let jsonData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyString = String(data: jsonData, encoding: .utf8) else {
            return String(data: data, encoding: .utf8)
        }
        return prettyString
    }
}
