import Foundation
import Web3Wallet

final class SessionRequestInteractor {
    func approve(sessionRequest: Request) async throws {
        do {
            let result = try Signer.sign(request: sessionRequest)
            try await Web3Wallet.instance.respond(
                topic: sessionRequest.topic,
                requestId: sessionRequest.id,
                response: .response(result)
            )
        } catch {
            throw error
        }
    }

    func reject(sessionRequest: Request) async throws {
        try await Web3Wallet.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .error(.init(code: 0, message: ""))
        )
    }
}
