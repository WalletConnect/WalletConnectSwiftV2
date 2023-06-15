import Foundation

import UIKit

#if SWIFT_PACKAGE
public typealias VerifyContext = WalletConnectVerify.VerifyContext
#endif

/// Web3Modal instance wrapper
///
/// ```Swift
/// let metadata = AppMetadata(
///     name: "Swift dapp",
///     description: "dapp",
///     url: "dapp.wallet.connect",
///     icons:  ["https://my_icon.com/1"]
/// )
/// Web3Modal.configure(metadata: metadata)
/// Web3Modal.instance.getSessions()
/// ```
public class Web3Modal {
    /// Web3Modalt client instance
    public static var instance: Web3ModalClient = {
        guard let config = Web3Modal.config else {
            fatalError("Error - you must call Web3Modal.configure(_:) before accessing the shared instance.")
        }
        return Web3ModalClient(
            signClient: Sign.instance,
            pairingClient: Pair.instance as! (PairingClientProtocol & PairingInteracting & PairingRegisterer)
        )
    }()
    
    struct Config {
        let projectId: String
        var sessionParams: SessionParams
    }
    
    private(set) static var config: Config!

    private init() {}

    /// Wallet instance wallet config method.
    /// - Parameters:
    ///   - metadata: App metadata
    public static func configure(
        projectId: String,
        metadata: AppMetadata,
        sessionParams: SessionParams = .default
    ) {
        Pair.configure(metadata: metadata)
        Web3Modal.config = Web3Modal.Config(projectId: projectId, sessionParams: sessionParams)
    }
    
    public static func set(sessionParams: SessionParams) {
        Web3Modal.config.sessionParams = sessionParams
    }
    
    public static func present(from presentingViewController: UIViewController? = nil) {
        guard let vc = presentingViewController ?? topViewController() else {
            assertionFailure("No controller found for presenting modal")
            return
        }
        
        if #available(iOS 14.0, *) {
            let modal = Web3ModalSheetController()
            vc.present(modal, animated: true)
        }
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
