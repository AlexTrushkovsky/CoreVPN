//
//  Support.swift
//  CoreVPN
//
//  Created by Алексей Трушковский on 23.12.2021.
//

import Foundation
import NetworkExtension
import PlainPing

enum CoreVPNConnectionState {
    case connected
    case connecting
    case disconnected
    case disconnecting
    case error
}

internal class CoreVPNSupport {
    
    private var servers: [CoreVPNServerModel]
    private var vpnProtocol: CoreVPNProtocol
    required init(vpnProtocol: CoreVPNProtocol, servers: [CoreVPNServerModel]) {
        self.servers = servers
        self.vpnProtocol = vpnProtocol
    }
    
    
    func getConnectionStatus() -> CoreVPNConnectionState {
        let status = NEVPNManager.shared().connection.status
        switch status {
        case NEVPNStatus.invalid:
            return .error
        case NEVPNStatus.disconnected:
            return .disconnected
        case NEVPNStatus.connecting:
            return .connecting
        case NEVPNStatus.connected:
            return .connected
        case NEVPNStatus.reasserting:
            return .error
        case NEVPNStatus.disconnecting:
            return .disconnected
        @unknown default:
            return .error
        }
    }
    
    
    func selectServer(server: CoreVPNServerModel) {
        UserDefaults.standard.setValue(server.userName, forKey: "coreVpnUsername")
        UserDefaults.standard.setValue(server.ip, forKey: "coreVpnServer")
        UserDefaults.standard.setValue(server.password, forKey: "coreVpnPass")
        if self.vpnProtocol == .L2TP {
            UserDefaults.standard.setValue(server.l2tpPSK, forKey: "coreVpnPSK")
        } else if self.vpnProtocol == .IKEv2 {
            UserDefaults.standard.setValue(server.ikev2ID, forKey: "coreVpnID")
        }
    }
    
    func selectOptimalServer() {
        getPingList { result in
            var optimalPing = 9999.9
            for item in result {
                if item.value < optimalPing {
                    optimalPing = item.value
                }
            }
            
            if let ping = result.first(where: { $0.value == optimalPing }) {
                if let index = servers.firstIndex(where: { $0.ip == ping.key }) {
                    self.selectServer(server: servers[index])
                } else {
                    if let server = servers.first {
                        self.selectServer(server: server)
                    }
                }
            }
            
        }
    }
    
    func getPingList(completion: ([String: Double]) -> ()) {
        var pingList = [String: Double]()
        var serverList = servers
        
        while serverList.count != 0 {
            let server = serverList.removeFirst().ip
            self.ping(server: server) { ping in
                pingList[server] = ping
            }
        }
        completion(pingList)
    }
    
    func offsetFrom(date: Date) -> String {
        let dayHourMinuteSecond: Set<Calendar.Component> = [.day, .hour, .minute, .second]
        let difference = NSCalendar.current.dateComponents(dayHourMinuteSecond, from: date, to: Date())
        
        var seconds = "\(difference.second ?? 0)"
        var minutes = "\(difference.minute ?? 0)"
        var hours = "\(difference.hour ?? 0)"
        
        if hours.count == 1 {
            hours = "0\(hours)"
        }
        if minutes.count == 1 {
            minutes = "0\(minutes)"
        }
        if seconds.count == 1 {
            seconds = "0\(seconds)"
        }
        return hours + ":" + minutes + ":" + seconds
    }
 
    private func ping(server: String, completion: @escaping (Double?) -> ()) {
        PlainPing.ping(server) { elapsedTimeMs, error in
            if let latency = elapsedTimeMs {
               completion(latency)
            }
            if let error = error {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
}
