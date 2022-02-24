
import Foundation
import WalletConnectKMS

// TODO: Come up with better naming conventions
public protocol KeyManagementServiceProtocol {
    func createX25519KeyPair() throws -> AgreementPublicKey
    func createSymmetricKey(_ topic: String) throws -> SymmetricKey 
    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws
    func setAgreementSecret(_ agreementSecret: AgreementSecret, topic: String) throws
    func setSymmetricKey(_ symmetricKey: SymmetricKey, for topic: String) throws
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey?
    func getAgreementSecret(for topic: String) throws -> AgreementSecret?
    func getSymmetricKey(for topic: String) throws -> SymmetricKey?
    func deletePrivateKey(for publicKey: String)
    func deleteAgreementSecret(for topic: String)
    func deleteSymmetricKey(for topic: String)
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret
}

extension KeyManagementService: KeyManagementServiceProtocol {}
