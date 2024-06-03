import Foundation

class AuthenticateTransportTypeSwitcher {
    public enum Errors: Error {
        case badUniversalLink
    }

    private let linkAuthRequester: LinkAuthRequester
    private let pairingClient: PairingClient
    private let logger: ConsoleLogging
    private let appRequestService: SessionAuthRequestService
    private let appProposeService: AppProposeService

    init(linkAuthRequester: LinkAuthRequester,
         pairingClient: PairingClient,
         logger: ConsoleLogging,
         appRequestService: SessionAuthRequestService,
         appProposeService: AppProposeService) {
        self.linkAuthRequester = linkAuthRequester
        self.pairingClient = pairingClient
        self.logger = logger
        self.appRequestService = appRequestService
        self.appProposeService = appProposeService
    }

    func authenticate(
        _ params: AuthRequestParams,
        walletUniversalLink: String? = nil
    ) async throws -> WalletConnectURI? {

        if let walletUniversalLink = walletUniversalLink,
           !walletUniversalLink.starts(with: "https://") {
            throw Errors.badUniversalLink
        }

        do {
            if let walletUniversalLink = walletUniversalLink {
                let _ = try await linkAuthRequester.request(params: params, walletUniversalLink: walletUniversalLink)
                return nil
            }
        } catch {
            guard case LinkAuthRequester.Errors.walletLinkSupportNotProven = error else {
                throw error
            }
            // Continue with relay if the error is walletLinkSupportNotProven
        }

        let pairingURI = try await pairingClient.create(
            methods: [SessionAuthenticatedProtocolMethod.responseApprove().method]
        )
        logger.debug("Requesting Authentication on existing pairing")
        try await appRequestService.request(params: params, topic: pairingURI.topic)

        let namespaces = try ProposalNamespaceBuilder.buildNamespace(from: params)
        try await appProposeService.propose(
            pairingTopic: pairingURI.topic,
            namespaces: [:],
            optionalNamespaces: namespaces,
            sessionProperties: nil,
            relay: RelayProtocolOptions(protocol: "irn", data: nil)
        )
        return pairingURI
    }
}
