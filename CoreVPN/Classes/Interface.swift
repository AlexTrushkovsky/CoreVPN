//
//  Interface.swift
//  CoreVPN
//
//  Created by Алексей Трушковский on 23.12.2021.
//

import Foundation
import NetworkExtension

public protocol CoreVPNDelegate {
    func serverChanged(server: CoreVPNServerModel)
    func connenctionTimeChanged(time: String)
    func connectionStateChanged(state: CoreVPNConnectionState)
}

public struct CoreVPNServerModel {
    public var vpnProtocol: String
    public var ip: String
    public var userName: String
    public var password: String
    public var ikev2ID: String?
    public var l2tpPSK: String?
    public var locationName: String?
    public var locationImageLink: String?
    
    
    public init(ip: String, userName: String, password: String, locationName: String? = nil, locationImageLink: String? = nil, ikev2ID: String? = nil, l2tpPSK: String? = nil, vpnProtocol: String) {
        self.ip = ip
        self.userName = userName
        self.password = password
        self.ikev2ID = ikev2ID
        self.l2tpPSK = l2tpPSK
        self.locationName = locationName
        self.locationImageLink = locationImageLink
        self.vpnProtocol = vpnProtocol
    }
}

public final class CoreVPN {
    public var delegate: CoreVPNDelegate
    private var support: CoreVPNSupport
    private var service: CoreVPNService
    
    private var servers: [CoreVPNServerModel]
    
    public var connectedDate: Date?
    public var connectedTimeDescription: String?
    public var connectionState: CoreVPNConnectionState
    
    private var timer = Timer()
    
    public required init(serviceName: String, servers: [CoreVPNServerModel], delegate: CoreVPNDelegate) {
        self.delegate = delegate
        self.servers = servers
        self.support = CoreVPNSupport(servers: servers)
        self.connectionState = support.getConnectionStatus()
        self.service = CoreVPNService(serviceName: serviceName)
        self.scheduledTimerWithTimeInterval()
        
        self.delegate.connectionStateChanged(state: self.support.getConnectionStatus())
        if let server = getSelectedServer() {
            self.delegate.serverChanged(server: server)
        }
        if self.support.getConnectionStatus() != .connected {
            self.delegate.connenctionTimeChanged(time: "00:00:00")
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: nil, using: { notification in
            self.connectionState = self.support.getConnectionStatus()
            self.delegate.connectionStateChanged(state: self.support.getConnectionStatus())
        })
    }
    
    private func scheduledTimerWithTimeInterval() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    @objc private func updateCounting() {
        if let connectedDate = NEVPNManager.shared().connection.connectedDate {
            self.connectedDate = connectedDate
            self.connectedTimeDescription = support.offsetFrom(date: connectedDate)
            self.delegate.connenctionTimeChanged(time: support.offsetFrom(date: connectedDate))
        }
    }
    
    public func getSelectedServer() -> CoreVPNServerModel? {
        return support.getSelectedServer()
    }
    
    public func selectServer(server: CoreVPNServerModel) {
        support.selectServer(server: server)
        service.disconnectVPN()
        delegate.serverChanged(server: server)
    }
    
    public func getOptimalServer(completion: @escaping ((CoreVPNServerModel) -> ())) {
        support.getOptimalServer { server in
            completion(server)
        }
    }
    
    public func getPingList(completion: @escaping ([String: Double]) -> ()) {
        support.getPingList { list in
            completion(list)
        }
    }
    
    public func connect() {
        if !self.support.isServerPicked() {
            getOptimalServer { server in
                self.selectServer(server: server)
            }
        }
        self.service.connectVPN()
    }
    
    public func disconnect() {
        self.service.disconnectVPN()
        self.delegate.connenctionTimeChanged(time: "00:00:00")
    }
    
}
