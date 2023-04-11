
import Foundation

class PushSubscribeService {

    func subscribe(publicKey: String, account: Account, onSign: @escaping SigningCallback) async throws {

        logger.debug("Subscribing for Push")

        let peerPublicKey = try AgreementPublicKey(hex: publicKey)
        let subscribeTopic = peerPublicKey.rawRepresentation.sha256().toHexString()



        let keys = try generateAgreementKeys(peerPublicKey: peerPublicKey)
        let pushTopic = keys.derivedTopic()

        _ = try await identityClient.register(account: account, onSign: onSign)

        try kms.setAgreementSecret(keys, topic: responseTopic)


    }





    private func generateAgreementKeys(peerPublicKey: AgreementPublicKey) throws -> AgreementKeys {
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPublicKey.hexRepresentation)
        return keys
    }
}
