import WalletConnectKMS
@testable import WalletConnectRelay
import Foundation

struct ED25519DIDKeyFactoryMock: DIDKeyFactory {
    var did: String!
    func make(pubKey: Data) -> String {
        return did
    }
}
