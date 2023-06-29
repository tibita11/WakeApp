//
//  Network.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/29.
//

import Network

final class Network {
    static let shared = Network()
    private let monitor = NWPathMonitor()

    func setUp() {
        monitor.start(queue: .global(qos: .background))
    }

    func isOnline() -> Bool {
        return monitor.currentPath.status == .satisfied
    }
}
