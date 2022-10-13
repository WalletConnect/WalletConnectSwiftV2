import WalletConnectKMS
@testable import WalletConnectRelay
import Foundation

class ED25519DIDKeyFactoryMock: DIDKeyFactory {
    var did: String!
    func make(pubKey: Data, prefix: Bool) -> String {
        return did
    }
}
