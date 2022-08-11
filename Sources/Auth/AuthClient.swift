import Foundation

class AuthClient {
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

    func request(params: RequestParams) async throws -> String {
        let uri = try await appPairService.create()
        try await appRequestService.request(params: params, topic: uri.topic)
        return uri.absoluteString
    }

    func pair(uri: String) async throws {
        guard let pairingURI = WalletConnectURI(string: uri) else {
            throw Errors.malformedPairingURI
        }
        try await walletPairService.pair(pairingURI)
    }
}
