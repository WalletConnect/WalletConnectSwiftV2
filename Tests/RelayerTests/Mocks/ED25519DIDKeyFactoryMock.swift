import WalletConnectKMS
@testable import WalletConnectRelay
import Foundation

struct ED25519DIDKeyFactoryMock: ED25519DIDKeyFactory {
    var did: String!
    func make(pubKey: Data) -> String {
        return did
    }
}
