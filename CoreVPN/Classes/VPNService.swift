//
//  VPNService.swift
//  CoreVPN
//
//  Created by Алексей Трушковский on 23.12.2021.
//

import Foundation
import NetworkExtension

class CoreVPNService {
    private var vpnProtocol: CoreVPNProtocol
    private var serviceName: String
    
    required init(vpnProtocol: CoreVPNProtocol, serviceName: String) {
        self.vpnProtocol = vpnProtocol
        self.serviceName = serviceName
    }
    
    private let vpnManager = NEVPNManager.shared()
    
    private var vpnLoadHandler: (Error?) -> Void { return
        { (error:Error?) in
            if ((error) != nil) {
                print("Could not load VPN Configurations")
                return;
            }
            
            let kcs = KeychainService(serviceName: self.serviceName)
            
            if self.vpnProtocol == .IKEv2 {
                let protocolIKEv2 = NEVPNProtocolIKEv2()
                kcs.save(key: "coreVpnPass", value: UserDefaults.standard.string(forKey: "coreVpnPass") ?? "")
                protocolIKEv2.passwordReference = kcs.load(key: "coreVpnPass")
                protocolIKEv2.username = UserDefaults.standard.string(forKey: "coreVpnUsername")
                protocolIKEv2.serverAddress = UserDefaults.standard.string(forKey: "coreVpnIP")
                protocolIKEv2.remoteIdentifier = UserDefaults.standard.string(forKey: "coreVpnID")
                protocolIKEv2.localIdentifier = UserDefaults.standard.string(forKey: "coreVpnID")
                protocolIKEv2.useExtendedAuthentication = true
                protocolIKEv2.disconnectOnSleep = false
                protocolIKEv2.disableMOBIKE = false
                protocolIKEv2.disableRedirect = false
                protocolIKEv2.enableRevocationCheck = false
                protocolIKEv2.useConfigurationAttributeInternalIPSubnet = false
                protocolIKEv2.authenticationMethod = .none
                protocolIKEv2.deadPeerDetectionRate = .medium
                protocolIKEv2.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
                protocolIKEv2.childSecurityAssociationParameters.integrityAlgorithm = .SHA384
                protocolIKEv2.childSecurityAssociationParameters.diffieHellmanGroup = .group20
                protocolIKEv2.childSecurityAssociationParameters.lifetimeMinutes = 1440
                protocolIKEv2.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
                protocolIKEv2.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA384
                protocolIKEv2.ikeSecurityAssociationParameters.diffieHellmanGroup = .group20
                protocolIKEv2.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
                self.vpnManager.protocolConfiguration = protocolIKEv2
                self.vpnManager.localizedDescription = self.serviceName
                self.vpnManager.isEnabled = true
                self.vpnManager.saveToPreferences(completionHandler: self.vpnSaveHandler)
            } else if self.vpnProtocol == .L2TP {
                let protocolL2TP = NEVPNProtocolIPSec()
                protocolL2TP.username = UserDefaults.standard.string(forKey: "coreVpnUsername")
                protocolL2TP.serverAddress = UserDefaults.standard.string(forKey: "coreVpnIP")
                protocolL2TP.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
                kcs.save(key: "coreVpnPSK", value: UserDefaults.standard.string(forKey: "coreVpnPSK") ?? "")
                kcs.save(key: "coreVpnPass", value: UserDefaults.standard.string(forKey: "coreVpnPass") ?? "")
                protocolL2TP.sharedSecretReference = kcs.load(key: "coreVpnPSK")
                protocolL2TP.passwordReference = kcs.load(key: "coreVpnPass")
                protocolL2TP.useExtendedAuthentication = true
                protocolL2TP.disconnectOnSleep = false
                self.vpnManager.protocolConfiguration = protocolL2TP
                self.vpnManager.localizedDescription = self.serviceName
                self.vpnManager.isEnabled = true
                self.vpnManager.saveToPreferences(completionHandler: self.vpnSaveHandler)
            }
        }
    }
    
    private var vpnSaveHandler: (Error?) -> Void { return
        { (error:Error?) in
            if (error != nil) {
                print("Could not save VPN Configurations")
                return
            } else {
                do {
                    try self.vpnManager.connection.startVPNTunnel()
                } catch let error {
                    print("Error starting VPN Connection \(error.localizedDescription)");
                }
            }
        }
    }
    
    public func connectVPN() {
        self.vpnManager.loadFromPreferences(completionHandler: self.vpnLoadHandler)
    }
    
    
    public func disconnectVPN() ->Void {
        self.vpnManager.connection.stopVPNTunnel()
    }
    
}
