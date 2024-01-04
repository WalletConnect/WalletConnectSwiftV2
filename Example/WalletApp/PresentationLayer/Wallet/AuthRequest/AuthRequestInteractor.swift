import Foundation

import Web3Wallet
import WalletConnectRouter

final class AuthRequestInteractor {

    private let messageSigner: MessageSigner

    init(messageSigner: MessageSigner) {
        self.messageSigner = messageSigner
    }

    
    func approve(request: AuthenticationRequest, importAccount: ImportAccount) async throws -> Bool {
        let account = importAccount.account
        var auths = [AuthObject]()


        try request.payload.chains.forEach { chain in

            let SIWEmessages = try Web3Wallet.instance.formatAuthMessage(payload: request.payload, account: account)

            let signature = try messageSigner.sign(
                message: SIWEmessages,
                privateKey: Data(hex: importAccount.privateKey),
                type: .eip191)



            let auth = try Web3Wallet.instance.makeAuthObject(authRequest: request, signature: signature, account: account)


            auths.append(auth)
        }


        try await Web3Wallet.instance.approveSessionAuthenticate(requestId: request.id, auths: auths)

        /* Redirect */
        if let uri = request.requester.redirect?.native {
            WalletConnectRouter.goBack(uri: uri)
            return false
        } else {
            return true
        }
    }

    func reject(request: AuthenticationRequest) async throws {
        try await Web3Wallet.instance.rejectSession(requestId: request.id)

        /* Redirect */
        if let uri = request.requester.redirect?.native {
            WalletConnectRouter.goBack(uri: uri)
        }
    }

    func formatted(request: AuthenticationRequest, account: Account) -> String {
        return try! Web3Wallet.instance.formatAuthMessage(
            payload: request.payload,
            account: account
        )
    }
}
