//
//  NetworkReachabilityMonitor.swift
//  EONetworkLayer
//
//  Created by Fazliddinov Iskandar on 25/05/25.
//

import Foundation
import Combine
import Network


public final class NetworkReachabilityMonitor: @unchecked Sendable {
    public static let shared = NetworkReachabilityMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private let subject = PassthroughSubject<Bool, Never>()
    
    public var isConnected: Bool = true
    public var connectionRestoredPublisher: AnyPublisher<Void, Never> {
        subject
            .removeDuplicates()
            .filter { $0 } // Только когда стало true
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let status = (path.status == .satisfied)
            self.isConnected = status
            self.subject.send(status)
        }
        monitor.start(queue: queue)
    }
}
