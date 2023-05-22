
import WalletConnectUtils
import Foundation
import WalletConnectIdentity
import WalletConnectSign
import Combine

public final class Web3Modal {

    static var session: Session?

    private init() { }
    
    public static func personal_sign(message: String) async -> SigningResult {
        
        guard let session = Web3Modal.session else {
            return .rejected
        }
        
        let account = session.namespaces.first!.value.accounts.first!.absoluteString
//        let message = "keys.walletconnect.com wants you to sign in with your Ethereum account:\n\(account)\n\n\nURI: https://keys.walletconnect.com\nVersion: 1\nChain ID: 1\nNonce: 7ed680863f82a49b4d1b48b5b7aeee0d5bcf84fd9fecd1104ce37356c8d9599e\nIssued At: 2023-05-22T09:02:23Z\nResources:\n- did:key:z6MkicwrBBSCujzapyXw98YsfSJqMpZ9v2QityADfc79CZtV"
        
        let method = "personal_sign"
        let requestParams =  AnyCodable(
            [message, account]
            
//            // Can be unhashed message probably?
//            ["0x4d7920656d61696c206973206a6f686e40646f652e636f6d202d2031363533333933373535313531", account]
        )

        let request = Request(
            topic: session.topic,
            method: method,
            params: requestParams,
            chainId: Blockchain("eip155:1")!
        )
        
        try? await Sign.instance.request(params: request)
        
        let response = try? await Sign.instance.sessionResponsePublisher.async()
        
        switch response?.result {
        case .error(_):
            return .rejected
        case let .response(response):
            guard let signatureResponse = try? response.get(String.self) else {
                return .rejected
            }
                 
            return .signed(CacaoSignature(t: .eip191, s: signatureResponse))
        case .none:
            return .rejected
        }
    }
}

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(with: .success(value))
                }
        }
    }
}
