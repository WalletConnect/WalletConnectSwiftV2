import Foundation
import WalletConnectKMS

actor AuthRespondService {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
    }

    func respond(respondParams: RespondParams) async throws {

//        B generates keyPair Y and generates shared symKey R.
        let pubKey = try kms.createX25519KeyPair()
        kms.performKeyAgreement(selfPublicKey: pubKey, peerPublicKey: <#T##String#>)

//        B encrypts response with symKey R as type 1 envelope.

//        B sends response on response topic.
    }
}
