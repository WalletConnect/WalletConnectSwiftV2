import Foundation

public final class HistoryClient {

    private let keyserver: URL
    private let networkingClient: NetworkInteracting
    private let identityClient: IdentityClient

    init(keyserver: URL, networkingClient: NetworkInteracting, identityClient: IdentityClient) {
        self.keyserver = keyserver
        self.networkingClient = networkingClient
        self.identityClient = identityClient
    }

    public func fetchHistory(account: Account, topic: String, appAuthenticationKey: String, host: String) async throws -> [NotifyMessage] {
        let identityKey = try identityClient.getInviteKey(for: account)
        let dappAuthKey = try DIDKey(did: appAuthenticationKey)
        let app = DIDWeb(host: host)

        let requestPayload = NotifyGetNotificationsRequestPayload(
            identityKey: DIDKey(rawData: identityKey.rawRepresentation),
            keyserver: keyserver.absoluteString,
            dappAuthKey: dappAuthKey,
            app: app,
            limit: 50,
            after: nil
        )

        let wrapper = try identityClient.signAndCreateWrapper(payload: requestPayload, account: account)

        let protocolMethod = NotifyGetNotificationsProtocolMethod()
        let request = RPCRequest(method: protocolMethod.method, params: wrapper)

        let response = try await networkingClient.awaitResponse(
            request: request,
            topic: topic,
            method: protocolMethod,
            requestOfType: NotifyGetNotificationsRequestPayload.Wrapper.self,
            responseOfType: NotifyGetNotificationsResponsePayload.Wrapper.self,
            envelopeType: .type0
        )

        let (responsePayload, _) = try NotifyGetNotificationsResponsePayload.decodeAndVerify(from: response)

        return responsePayload.messages
    }
}
