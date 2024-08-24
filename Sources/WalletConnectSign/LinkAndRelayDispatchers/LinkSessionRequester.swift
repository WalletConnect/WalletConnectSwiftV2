
import Foundation

final class LinkSessionRequester {
    private let sessionStore: WCSessionStorage
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher
    private let logger: ConsoleLogging
    private let eventsClient: EventsClientProtocol

    init(
        sessionStore: WCSessionStorage,
        linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
        logger: ConsoleLogging,
        eventsClient: EventsClientProtocol
    ) {
        self.sessionStore = sessionStore
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.logger = logger
        self.eventsClient = eventsClient
    }

    func request(_ request: Request) async throws -> String? {
        logger.debug("will request on session topic: \(request.topic)")
        guard let session = sessionStore.getSession(forTopic: request.topic) else {
            logger.debug("Could not find session for topic \(request.topic)")
            throw WalletConnectError.noSessionMatchingTopic(request.topic)
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            logger.debug("Invalid namespaces")
            throw WalletConnectError.invalidPermissions
        }
        // it's safe to force unwrap because redirect was used during session creation before
        let peerUniversalLink = session.peerParticipant.metadata.redirect!.universal!
        let chainRequest = SessionType.RequestParams.Request(method: request.method, params: request.params, expiryTimestamp: request.expiryTimestamp)
        let sessionRequestParams = SessionType.RequestParams(request: chainRequest, chainId: request.chainId)
        let ttl = try request.calculateTtl()
        let protocolMethod = SessionRequestProtocolMethod(ttl: ttl)
        let rpcRequest = RPCRequest(method: protocolMethod.method, params: sessionRequestParams, rpcid: request.id)
        let envelope = try await linkEnvelopesDispatcher.request(topic: session.topic, request: rpcRequest, peerUniversalLink: peerUniversalLink, envelopeType: .type0)
        Task(priority: .low) { eventsClient.saveMessageEvent(.sessionRequestLinkModeSent(request.id)) }
        return envelope
    }
}
