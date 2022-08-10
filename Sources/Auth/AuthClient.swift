import Foundation
import Combine

class AuthClient {
    private var authRequestPublisherSubject = PassthroughSubject<(id: RPCID, message: String), Never>()
    public var authRequestPublisher: AnyPublisher<(id: RPCID, message: String), Never> {
        authRequestPublisherSubject.eraseToAnyPublisher()
    }

    private var authResponsePublisherSubject = PassthroughSubject<(id: RPCID, cacao: Cacao), Never>()
    public var authResponsePublisher: AnyPublisher<(id: RPCID, cacao: Cacao), Never> {
        authResponsePublisherSubject.eraseToAnyPublisher()
    }

    enum Errors: Error {
        case malformedPairingURI
    }

    private let appPairService: AppPairService
    private let appRequestService: AppRequestService
    private let appRespondSubscriber: AppRespondSubscriber

    private let walletPairService: WalletPairService
    private let walletRequestSubscriber: WalletRequestSubscriber
    private let walletRespondService: WalletRespondService

    init(appPairService: AppPairService,
         appRequestService: AppRequestService,
         appRespondSubscriber: AppRespondSubscriber,
         walletPairService: WalletPairService,
         walletRequestSubscriber: WalletRequestSubscriber,
         walletRespondService: WalletRespondService) {
        self.appPairService = appPairService
        self.appRequestService = appRequestService
        self.walletPairService = walletPairService
        self.walletRequestSubscriber = walletRequestSubscriber
        self.walletRespondService = walletRespondService
        self.appRespondSubscriber = appRespondSubscriber
    }

    public func pair(uri: String) async throws {
        guard let pairingURI = WalletConnectURI(string: uri) else {
            throw Errors.malformedPairingURI
        }
        try await walletPairService.pair(pairingURI)
    }

    public func request(_ params: RequestParams) async throws -> String {
        let uri = try await appPairService.create()
        try await appRequestService.request(params: params, topic: uri.topic)
        return uri.absoluteString
    }

    public func respond(_ params: RespondParams) async throws {
        fatalError("not implemented")
    }

    public func getPendingRequests() -> [AuthRequest] {
        fatalError("not implemented")
    }
}

public struct AuthRequest: Equatable, Codable {

}
