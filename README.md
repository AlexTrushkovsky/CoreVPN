# CoreVPN

## Example
See Example to get started quickly.
To run the example project, clone the repo, and run `pod install`.
Then add next capability`s to your app target:
    - Personal VPN
    - Network Extensions (Packet Tunnel, App Proxy)
    
    
import CoreVPN

class ViewController: UIViewController {
   var corevpn: CoreVPN!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.corevpn = CoreVPN(serviceName: "Name_of_your_vpn (you will see that name in settings)", servers: corevpnServers, delegate: self)
    }
    
    @IBAction func connect(_ sender: UIButton) {
        corevpn.connect()
    }
    
    @IBAction func disconnect(_ sender: UIButton) {
        corevpn.disconnect()
    }
    
    @IBAction func chooseOptimalLocation(_ sender: UIButton) {
        corevpn.getOptimalServer { server in
            // select best server based on ping
            self.corevpn.selectServer(server: server)
        }
    }
    
    @IBAction func chooseRandomLocation(_ sender: UIButton) {
        if let server = corevpnServers.randomElement() {
            // select server you need
            corevpn.selectServer(server: server)
        }
    }
}

extension ViewController: CoreVPNDelegate {
    func serverChanged(server: CoreVPNServerModel) {
        // update view or make smth you need
    }
    
    func connenctionTimeChanged(time: String) {
        // update view or make smth you need
    }
    
    func connectionStateChanged(state: CoreVPNConnectionState) {
        // update view or make smth you need
    }
}

## Requirements
iOS >= 9.0
## Installation

CoreVPN is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CoreVPN'
```

## Author

Alexey Trushkovsky, trushkovskya@gmail.com

## License

CoreVPN is available under the MIT license. See the LICENSE file for more info.
