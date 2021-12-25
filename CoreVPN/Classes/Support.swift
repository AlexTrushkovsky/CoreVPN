//
//  Support.swift
//  CoreVPN
//
//  Created by Алексей Трушковский on 23.12.2021.
//

import Foundation
import NetworkExtension
import PlainPing

public enum CoreVPNConnectionState {
    case connected
    case connecting
    case disconnected
    case disconnecting
}

class CoreVPNSupport {
    
    private var servers: [CoreVPNServerModel]
    required init(servers: [CoreVPNServerModel]) {
        self.servers = servers
    }
    
    
    func getConnectionStatus() -> CoreVPNConnectionState {
        let status = NEVPNManager.shared().connection.status
        switch status {
        case NEVPNStatus.invalid, NEVPNStatus.disconnected, NEVPNStatus.reasserting:
            return .disconnected
        case NEVPNStatus.connecting:
            return .connecting
        case NEVPNStatus.connected:
            return .connected
        case NEVPNStatus.disconnecting:
            return .disconnecting
        @unknown default:
            return .disconnected
        }
    }
    
    
    func selectServer(server: CoreVPNServerModel) {
        UserDefaults.standard.setValue(server.vpnProtocol, forKey: "coreVpnProtocol")
        UserDefaults.standard.setValue(server.userName, forKey: "coreVpnUsername")
        UserDefaults.standard.setValue(server.ip, forKey: "coreVpnServer")
        UserDefaults.standard.setValue(server.password, forKey: "coreVpnPass")
        if server.vpnProtocol == "l2tp" {
            UserDefaults.standard.setValue(server.l2tpPSK, forKey: "coreVpnPSK")
        } else if server.vpnProtocol == "ikev2" {
            UserDefaults.standard.setValue(server.ikev2ID, forKey: "coreVpnID")
        }
        if let imagelink = server.locationImageLink {
            UserDefaults.standard.setValue(imagelink, forKey: "coreVpnImageLink")
        }
        if let locationName = server.locationName {
            UserDefaults.standard.setValue(locationName, forKey: "coreVpnLocationName")
        }
    }
    
    func getOptimalServer(completion: @escaping ((CoreVPNServerModel) -> ())) {
        getPingList { result in
            var optimalPing = 9999.9
            for item in result {
                if item.value < optimalPing {
                    optimalPing = item.value
                }
            }
            
            if let ping = result.first(where: { $0.value == optimalPing }) {
                if let index = self.servers.firstIndex(where: { $0.ip == ping.key }) {
                    completion(self.servers[index])
                }
            }
            if let server = self.servers.first {
                completion(server)
            }
        }
    }
    
    func getSelectedServer() -> CoreVPNServerModel? {
        let coreVpnProtocol = UserDefaults.standard.string(forKey: "coreVpnProtocol")
        let coreVpnUsername = UserDefaults.standard.string(forKey: "coreVpnUsername")
        let coreVpnServer = UserDefaults.standard.string(forKey: "coreVpnServer")
        let coreVpnPass = UserDefaults.standard.string(forKey: "coreVpnPass")
        let coreVpnPSK = UserDefaults.standard.string(forKey: "coreVpnPSK")
        let coreVpnID = UserDefaults.standard.string(forKey: "coreVpnID")
        let coreVpnImageLink = UserDefaults.standard.string(forKey: "coreVpnImageLink")
        let coreVpnLocationName = UserDefaults.standard.string(forKey: "coreVpnLocationName")
        if let coreVpnServer = coreVpnServer,
           let coreVpnUsername = coreVpnUsername,
           let coreVpnPass = coreVpnPass,
           let coreVpnProtocol = coreVpnProtocol {
        return CoreVPNServerModel(ip: coreVpnServer, userName: coreVpnUsername, password: coreVpnPass, locationName: coreVpnLocationName, locationImageLink: coreVpnImageLink, ikev2ID: coreVpnID, l2tpPSK: coreVpnPSK, vpnProtocol: coreVpnProtocol)
        } else {
            return nil
        }
    }
    
//    func getPingList(completion: @escaping ([String: Double]) -> ()) {
//        var pingList = [String: Double]()
//        var serverList = servers
//        var semaphore = serverList.count {
//            didSet {
//                if semaphore == 0 {
//                    print(self.servers.count)
//                    completion(pingList)
//                }
//            }
//        }
//        let myGroup = DispatchGroup()
//        while serverList.count != 0 {
//            let server = serverList.removeFirst().ip
//            myGroup.enter()
//            self.ping(server: server) { ping in
//                pingList[server] = ping
//                print("\(server): \(ping)")
//                myGroup.leave()
//            }
//        }
//
//        myGroup.notify(queue: .main) {
//            print("Finished all requests.")
//        }
//
//    }
    
    
    func getPingList(completion: @escaping (([String: Double]) -> ())) {
        var pingList = [String: Double]()
        var serverList = servers
        pingNext()
        
        func pingNext() {
            guard serverList.count > 0 else {
                completion(pingList)
                return
            }
            
            let server = serverList.removeFirst().ip
            PlainPing.ping(server) { elapsedTimeMs, error in
                pingList[server] = elapsedTimeMs
                pingNext()
            }
        }
        
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
    
    func isServerPicked() -> Bool {
        if UserDefaults.standard.string(forKey: "coreVpnUsername") != nil,
           UserDefaults.standard.string(forKey: "coreVpnServer") != nil,
           UserDefaults.standard.string(forKey: "coreVpnPass") != nil
        {
            return true
        } else {
            return false
        }
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
