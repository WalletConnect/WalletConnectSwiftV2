import Foundation
import JSONRPC
import Combine

typealias RPCID = JSONRPC.RPCID

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
    private let appRequestService: AuthRequestService

    private let walletPairService: WalletPairService

    init(appPairService: AppPairService, appRequestService: AuthRequestService, walletPairService: WalletPairService) {
        self.appPairService = appPairService
        self.appRequestService = appRequestService
        self.walletPairService = walletPairService
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

    public func getPendingRequests() -> [Request] {
        fatalError("not implemented")
    }
}
