import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if SWIFT_PACKAGE
public typealias VerifyContext = WalletConnectVerify.VerifyContext
#endif

/// WalletConnectModal instance wrapper
///
/// ```Swift
/// let metadata = AppMetadata(
///     name: "Swift dapp",
///     description: "dapp",
///     url: "dapp.wallet.connect",
///     icons:  ["https://my_icon.com/1"]
/// )
/// WalletConnectModal.configure(projectId: PROJECT_ID, metadata: metadata)
/// WalletConnectModal.instance.getSessions()
/// ```
public class WalletConnectModal {
    /// WalletConnectModalt client instance
    public static var instance: WalletConnectModalClient = {
        guard let config = WalletConnectModal.config else {
            fatalError("Error - you must call WalletConnectModal.configure(_:) before accessing the shared instance.")
        }
        return WalletConnectModalClient(
            signClient: Sign.instance,
            pairingClient: Pair.instance as! (PairingClientProtocol & PairingInteracting & PairingRegisterer)
        )
    }()
    
    struct Config {
        let projectId: String
        var metadata: AppMetadata
        var sessionParams: SessionParams
        
        let recommendedWalletIds: [String]
        let excludedWalletIds: [String]
    }
    
    private(set) static var config: Config!

    private init() {}

    /// Wallet instance wallet config method.
    /// - Parameters:
    ///   - metadata: App metadata
    public static func configure(
        projectId: String,
        metadata: AppMetadata,
        sessionParams: SessionParams = .default,
        recommendedWalletIds: [String] = [],
        excludedWalletIds: [String] = [],
        accentColor: Color? = nil
    ) {
        Pair.configure(metadata: metadata)
        WalletConnectModal.config = WalletConnectModal.Config(
            projectId: projectId,
            metadata: metadata,
            sessionParams: sessionParams,
            recommendedWalletIds: recommendedWalletIds,
            excludedWalletIds: excludedWalletIds
        )
        
        if let accentColor {
            Color.accent = accentColor
        }
    }
    
    public static func set(sessionParams: SessionParams) {
        WalletConnectModal.config.sessionParams = sessionParams
    }
}

#if canImport(UIKit)

extension WalletConnectModal {
    
    public static func present(from presentingViewController: UIViewController? = nil) {
        guard let vc = presentingViewController ?? topViewController() else {
            assertionFailure("No controller found for presenting modal")
            return
        }
        
        let modal = WalletConnectModalSheetController()
        vc.present(modal, animated: true)
    }
    
    private static func topViewController(_ base: UIViewController? = nil) -> UIViewController? {
        
        let base = base ?? UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }?
            .rootViewController
        
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        
        return base
    }
}

#elseif canImport(AppKit)

import AppKit

extension WalletConnectModal {
    
    public static func present(from presentingViewController: NSViewController? = nil) {
        
        let modal = WalletConnectModalSheetController()
        presentingViewController!.presentAsModalWindow(modal)
    }
}

#endif

public struct SessionParams {
    public let requiredNamespaces: [String: ProposalNamespace]
    public let optionalNamespaces: [String: ProposalNamespace]?
    public let sessionProperties: [String: String]?
    
    public init(requiredNamespaces: [String : ProposalNamespace], optionalNamespaces: [String : ProposalNamespace]? = nil, sessionProperties: [String : String]? = nil) {
        self.requiredNamespaces = requiredNamespaces
        self.optionalNamespaces = optionalNamespaces
        self.sessionProperties = sessionProperties
    }
    
    public static let `default`: Self = {
        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
        let events: Set<String> = ["chainChanged", "accountsChanged"]
        let blockchains: Set<Blockchain> = [Blockchain("eip155:1")!]
        let namespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(
                chains: blockchains,
                methods: methods,
                events: events
            )
        ]
       
        return SessionParams(
            requiredNamespaces: namespaces,
            optionalNamespaces: nil,
            sessionProperties: nil
        )
    }()
}
