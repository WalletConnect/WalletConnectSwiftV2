import Foundation

import Web3Wallet
import WalletConnectRouter

final class SessionRequestInteractor {
    func respondSessionRequest(sessionRequest: Request, importAccount: ImportAccount) async throws -> Bool {
        do {
            let result = try Signer.sign(request: sessionRequest, importAccount: importAccount)
            try await Web3Wallet.instance.respond(
                topic: sessionRequest.topic,
                requestId: sessionRequest.id,
                response: .response(result)
            )
            /* Redirect */
            let session = getSession(topic: sessionRequest.topic)
            if let uri = session?.peer.redirect?.native {
                WalletConnectRouter.goBack(uri: uri)
                return false
            } else {
                return true
            }
        } catch {
            throw error
        }
    }

    func respondError(sessionRequest: Request) async throws {
        try await Web3Wallet.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .error(.init(code: 0, message: ""))
        )
        
        /* Redirect */
        let session = getSession(topic: sessionRequest.topic)
        if let uri = session?.peer.redirect?.native {
            WalletConnectRouter.goBack(uri: uri)
        }
    }
    
    func getSession(topic: String) -> Session? {
        return Web3Wallet.instance.getSessions().first(where: { $0.topic == topic })
    }
}
