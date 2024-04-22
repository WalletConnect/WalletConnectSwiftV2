
import Foundation

class SessionRequestDispatcher {
    private let relaySessionRequester: SessionRequester
    private let linkSessionRequester: LinkSessionRequester
    private let logger: ConsoleLogging
    private let sessionStore: WCSessionStorage

    init(
        relaySessionRequester: SessionRequester,
        linkSessionRequester: LinkSessionRequester,
        logger: ConsoleLogging,
        sessionStore: WCSessionStorage
    ) {
        self.relaySessionRequester = relaySessionRequester
        self.linkSessionRequester = linkSessionRequester
        self.logger = logger
        self.sessionStore = sessionStore
    }

    public func request(_ request: Request) async throws -> (String?) {

        guard let session = sessionStore.getSession(forTopic: request.topic), session.acknowledged else {
            logger.debug("Could not find session for topic \(request.topic)")
            throw WalletConnectError.noSessionMatchingTopic(request.topic)
        }
        let transportType = session.transportType

        switch transportType {
        case .relay:
            try await relaySessionRequester.request(request)
            return nil
        case .linkMode:
            return try await linkSessionRequester.request(request)
        }
    }
}


class SessionRequester {
    private let sessionStore: WCSessionStorage
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging

    init(
        sessionStore: WCSessionStorage,
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging
    ) {
        self.sessionStore = sessionStore
        self.networkingInteractor = networkingInteractor
        self.logger = logger
    }

    func request(_ request: Request) async throws {
        logger.debug("will request on session topic: \(request.topic)")
        guard let session = sessionStore.getSession(forTopic: request.topic), session.acknowledged else {
            logger.debug("Could not find session for topic \(request.topic)")
            return
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            logger.debug("Invalid namespaces")
            throw WalletConnectError.invalidPermissions
        }
        let chainRequest = SessionType.RequestParams.Request(method: request.method, params: request.params, expiryTimestamp: request.expiryTimestamp)
        let sessionRequestParams = SessionType.RequestParams(request: chainRequest, chainId: request.chainId)
        let ttl = try request.calculateTtl()
        let protocolMethod = SessionRequestProtocolMethod(ttl: ttl)
        let rpcRequest = RPCRequest(method: protocolMethod.method, params: sessionRequestParams, rpcid: request.id)
        try await networkingInteractor.request(rpcRequest, topic: request.topic, protocolMethod: SessionRequestProtocolMethod())
    }
}

class LinkSessionRequester {
    private let sessionStore: WCSessionStorage
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher
    private let logger: ConsoleLogging

    init(
        sessionStore: WCSessionStorage,
        linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
        logger: ConsoleLogging
    ) {
        self.sessionStore = sessionStore
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.logger = logger
    }

    func request(_ request: Request) async throws -> String? {
        logger.debug("will request on session topic: \(request.topic)")
        guard let session = sessionStore.getSession(forTopic: request.topic), session.acknowledged else {
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
        return try await linkEnvelopesDispatcher.request(topic: session.topic, request: rpcRequest, peerUniversalLink: peerUniversalLink, envelopeType: .type0)
    }
}
