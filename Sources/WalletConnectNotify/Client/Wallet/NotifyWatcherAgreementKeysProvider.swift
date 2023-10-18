import Foundation

final class NotifyWatcherAgreementKeysProvider {

    private let kms: KeyManagementServiceProtocol

    init(kms: KeyManagementServiceProtocol) {
        self.kms = kms
    }

    func generateAgreementKeysIfNeeded(notifyServerPublicKey: AgreementPublicKey, account: Account) throws -> (responseTopic: String, selfPubKeyY: Data) {

        let keyYStorageKey = storageKey(account: account)

        if 
            let responseTopic = kms.getTopic(for: keyYStorageKey),
            let agreement = kms.getAgreementSecret(for: responseTopic),
            let recoveredAgreement = try? kms.performKeyAgreement(
                selfPublicKey: agreement.publicKey,
                peerPublicKey: notifyServerPublicKey.hexRepresentation
            ), agreement == recoveredAgreement
        { 
            return (responseTopic: responseTopic, selfPubKeyY: agreement.publicKey.rawRepresentation)
        }
        else {
            let selfPubKeyY = try kms.createX25519KeyPair()
            let watchSubscriptionsTopic = notifyServerPublicKey.rawRepresentation.sha256().toHexString()

            let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKeyY, peerPublicKey: notifyServerPublicKey.hexRepresentation)

            try kms.setSymmetricKey(agreementKeys.sharedKey, for: watchSubscriptionsTopic)
            let responseTopic = agreementKeys.derivedTopic()

            try kms.setAgreementSecret(agreementKeys, topic: responseTopic)

            // save for later under dapp's account + pub key
            try kms.setTopic(responseTopic, for: keyYStorageKey)

            return (responseTopic: responseTopic, selfPubKeyY: selfPubKeyY.rawRepresentation)
        }
    }

    func removeAgreement(account: Account) {
        let keyYStorageKey = storageKey(account: account)
        kms.deleteTopic(for: keyYStorageKey)
    }
}

private extension NotifyWatcherAgreementKeysProvider {

    func storageKey(account: Account) -> String {
        return "watchSubscriptionResponseTopic_\(account.absoluteString)"
    }
}
