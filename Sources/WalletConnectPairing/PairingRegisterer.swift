import Foundation
import WalletConnectNetworking

public protocol PairingRegisterer {
    func register(method: ProtocolMethod)
}
