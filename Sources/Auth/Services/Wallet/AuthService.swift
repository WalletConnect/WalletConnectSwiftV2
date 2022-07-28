import Foundation

actor AuthService {
    enum Errors: Error {
        case malformedPairingURI
    }

    private let appPairService: AppPairService

    private let walletPairService: WalletPairService

    init(appPairService: AppPairService, walletPairService: WalletPairService) {
        self.appPairService = appPairService
        self.walletPairService = walletPairService
    }

    func connect() async throws -> String {
        let uri = try await appPairService.create()
        return uri.absoluteString
    }

    func pair(uri: String) async throws {
        guard let pairingURI = WalletConnectURI(string: uri) else {
            throw Errors.malformedPairingURI
        }
        try await walletPairService.pair(pairingURI)
    }

    func respond(respondParams: RespondParams) async throws {

    }
}
