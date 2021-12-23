//
//  Interface.swift
//  CoreVPN
//
//  Created by Алексей Трушковский on 23.12.2021.
//

import Foundation
import NetworkExtension

public enum CoreVPNProtocol {
    case IKEv2
    case L2TP
//    case OpenVPN
}

public struct CoreVPNServerModel {
    var ip: String
    var userName: String
    var password: String
    var ikev2ID: String?
    var l2tpPSK: String?
}

public final class CoreVPN {
    private var support: CoreVPNSupport
    private var service: CoreVPNService
    
    private var servers: [CoreVPNServerModel]
    
    public var connectedDate: Date?
    public var connectedTimeDescription: String?
    public var connectionState: CoreVPNConnectionState
    
    private var timer = Timer()
    
    public required init(vpnProtocol: CoreVPNProtocol, serviceName: String, servers: [CoreVPNServerModel]) {
        self.servers = servers
        self.support = CoreVPNSupport(vpnProtocol: vpnProtocol, servers: servers)
        self.connectionState = support.getConnectionStatus()
        self.service = CoreVPNService(vpnProtocol: vpnProtocol, serviceName: serviceName)
        scheduledTimerWithTimeInterval()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: nil, using: { notification in
            self.connectionState = self.support.getConnectionStatus()
        })
    }
    
    private func scheduledTimerWithTimeInterval() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    @objc private func updateCounting() {
        if let connectedDate = NEVPNManager.shared().connection.connectedDate {
            self.connectedDate = connectedDate
            self.connectedTimeDescription = support.offsetFrom(date: connectedDate)
        }
    }
    
    
    
    public func selectServer(server: CoreVPNServerModel) {
        support.selectServer(server: server)
    }
    
    public func selectOptimalServer() {
        support.selectOptimalServer()
    }
    
    public func getPingList(completion: ([String: Double]) -> ()) {
        support.getPingList { list in
            completion(list)
        }
    }
    
    public func connect() {
        self.service.connectVPN()
    }
    
    public func disconnect() {
        self.service.disconnectVPN()
    }
    
}
