//
//  ViewController.swift
//  CoreVPN_Example
//
//  Created by Алексей Трушковский on 24.12.2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import CoreVPN

class ViewController: UIViewController {
    @IBOutlet weak var connectionImage: UIImageView!
    @IBOutlet weak var connectionTime: UILabel!
    @IBOutlet weak var coneectionStatus: UILabel!
    @IBOutlet weak var serverIP: UILabel!
    @IBOutlet weak var serverLocation: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let corevpnServers = [
        CoreVPNServerModel(ip: "188.241.83.66", userName: "prd_test_j4d3vk6", password: "xpcnwg6abh", locationName: "France", locationImageLink: "https://firebasestorage.googleapis.com/v0/b/neovpn-dcede.appspot.com/o/images%2Ffrance.png?alt=media&token=e9f23470-fb86-4f08-8edf-5356c53e6e54", ikev2ID: "fr-012.whiskergalaxy.com", vpnProtocol: "ikev2"),
        CoreVPNServerModel(ip: "91.149.252.33", userName: "prd_test_j4d3vk6", password: "xpcnwg6abh", locationName: "Canada", locationImageLink: "https://firebasestorage.googleapis.com/v0/b/neovpn-dcede.appspot.com/o/images%2Fcanada.png?alt=media&token=3b783fac-dd2d-4cbc-91e2-cd6d917d0cab", ikev2ID: "ca-024.whiskergalaxy.com", vpnProtocol: "ikev2"),
        CoreVPNServerModel(ip: "107.150.22.194", userName: "prd_test_j4d3vk6", password: "xpcnwg6abh", locationName: "United States", locationImageLink: "https://firebasestorage.googleapis.com/v0/b/neovpn-dcede.appspot.com/o/images%2Fus.png?alt=media&token=1fcb2b9a-aa6e-403e-9400-fb45041d2a36", ikev2ID: "us-central-076.whiskergalaxy.com", vpnProtocol: "ikev2")
        
        
    ]
    
    var corevpn: CoreVPN!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.corevpn = CoreVPN(serviceName: "CoreVPN Test", servers: corevpnServers, delegate: self)
    }
    
    @IBAction func connect(_ sender: UIButton) {
        corevpn.connect()
    }
    
    @IBAction func disconnect(_ sender: UIButton) {
        corevpn.disconnect()
    }
    
    @IBAction func chooseOptimalLocation(_ sender: UIButton) {
        self.indicator.startAnimating()
        corevpn.getOptimalServer { server in
            self.corevpn.selectServer(server: server)
            self.indicator.stopAnimating()
        }
    }
    
    @IBAction func chooseRandomLocation(_ sender: UIButton) {
        if let server = corevpnServers.randomElement() {
            corevpn.selectServer(server: server)
        }
    }
}

extension ViewController: CoreVPNDelegate {
    func serverChanged(server: CoreVPNServerModel) {
        if let link = server.locationImageLink {
            self.connectionImage.downloaded(from: link)
        }
        self.serverLocation.text = server.locationName
        self.serverIP.text = server.ip
    }
    
    func connenctionTimeChanged(time: String) {
        self.connectionTime.text = time
    }
    
    func connectionStateChanged(state: CoreVPNConnectionState) {
        switch state {
        case .connected:
            self.coneectionStatus.text = "Connected"
            self.indicator.stopAnimating()
        case .connecting:
            self.coneectionStatus.text = "Connecting"
            self.indicator.startAnimating()
        case .disconnected:
            self.coneectionStatus.text = "Disconnected"
            self.indicator.stopAnimating()
        case .disconnecting:
            self.coneectionStatus.text = "Disconnecting"
            self.indicator.startAnimating()
        }
    }
    
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}
