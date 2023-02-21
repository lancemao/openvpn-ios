//
//  ViewController.swift
//  ns
//
//  Created by Lance Mao on 2022/1/3.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {

    var providerManager: NETunnelProviderManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadProviderManager {
            self.configureVPN(serverAddress: "127.0.0.1", username: "uid", password: "pw123")
        }
     }

    func loadProviderManager(completion:@escaping () -> Void) {
       NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
           if error == nil {
               self.providerManager = managers?.first ?? NETunnelProviderManager()
               completion()
           }
       }
    }

    func configureVPN(serverAddress: String, username: String, password: String) {
        self.providerManager?.loadFromPreferences(completionHandler: { (error) in
            guard error == nil else {
                // Handle an occurred error
                return
            }

            // Assuming the app bundle contains a configuration file named 'client.ovpn' lets get its
            // Data representation
            guard
                let configurationFileURL = Bundle.main.url(forResource: "client", withExtension: "ovpn"),
                let configurationFileContent = try? Data(contentsOf: configurationFileURL)
            else {
                fatalError()
            }

            let tunnelProtocol = NETunnelProviderProtocol()

            // If the ovpn file doesn't contain server address you can use this property
            // to provide it. Or just set an empty string value because `serverAddress`
            // property must be set to a non-nil string in either case.
            tunnelProtocol.serverAddress = ""

            // The most important field which MUST be the bundle ID of our custom network
            // extension target.
            tunnelProtocol.providerBundleIdentifier = "cn.authing.ns.cn-authing-nsn"

            // Use `providerConfiguration` to save content of the ovpn file.
            tunnelProtocol.providerConfiguration = ["ovpn": configurationFileContent]

            // Provide user credentials if needed. It is highly recommended to use
            // keychain to store a password.
//            tunnelProtocol.username = "username"
//            tunnelProtocol.passwordReference = ... // A persistent keychain reference to an item containing the password

            // Finish configuration by assigning tunnel protocol to `protocolConfiguration`
            // property of `providerManager` and by setting description.
            self.providerManager?.protocolConfiguration = tunnelProtocol
            self.providerManager?.localizedDescription = "OpenVPN Client"

            self.providerManager?.isEnabled = true

            // Save configuration in the Network Extension preferences
            self.providerManager?.saveToPreferences(completionHandler: { (error) in
                if let error = error  {
                    // Handle an occurred error
                }
            })
            
            self.providerManager?.loadFromPreferences(completionHandler: { (error) in
                guard error == nil else {
                    // Handle an occurred error
                    return
                }

                do {
                    try self.providerManager?.connection.startVPNTunnel()
                } catch {
                    // Handle an occurred error
                    NSLog("Failed to start vpn: \(error)")
                }
            })
        })
    }

    func readFile(path: String) -> Data? {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent(path)
            return try Data(contentsOf: fileURL, options: .uncached)
        }
        catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
}

