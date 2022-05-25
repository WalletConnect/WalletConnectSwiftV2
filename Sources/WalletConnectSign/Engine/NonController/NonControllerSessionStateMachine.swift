
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class NonControllerSessionStateMachine {
    
    var onNamespacesUpdate: ((String, [String: SessionNamespace])->())?
    var onExpiryUpdate: ((String, Date) -> ())?
    
    private let sessionStore: WCSessionStorage
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         sessionStore: WCSessionStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.sessionStore = sessionStore
        self.logger = logger
        setUpWCRequestHandling()
    }
    
    private func setUpWCRequestHandling() {
        networkingInteractor.wcRequestPublisher.sink { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .sessionUpdate(let updateParams):
                onSessionUpdateNamespacesRequest(payload: subscriptionPayload, updateParams: updateParams)
            case .sessionExtend(let updateExpiryParams):
                onSessionUpdateExpiry(subscriptionPayload, updateExpiryParams: updateExpiryParams)
            default:
                return
            }
        }.store(in: &publishers)
    }
    
    // TODO: Update stored session namespaces
    private func onSessionUpdateNamespacesRequest(payload: WCRequestSubscriptionPayload, updateParams: SessionType.UpdateParams) {
        do {
            try Namespace.validate(updateParams.namespaces)
        } catch {
            networkingInteractor.respondError(for: payload, reason: .invalidUpdateNamespaceRequest)
            return
        }
        guard var session = sessionStore.getSession(forTopic: payload.topic) else {
            networkingInteractor.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
            return
        }
        guard session.peerIsController else {
            networkingInteractor.respondError(for: payload, reason: .unauthorizedUpdateNamespacesRequest)
            return
        }
        session.updateNamespaces(updateParams.namespaces)
        sessionStore.setSession(session)
        networkingInteractor.respondSuccess(for: payload)
        onNamespacesUpdate?(session.topic, updateParams.namespaces)
    }

    private func onSessionUpdateExpiry(_ payload: WCRequestSubscriptionPayload, updateExpiryParams: SessionType.UpdateExpiryParams) {
        let topic = payload.topic
        guard var session = sessionStore.getSession(forTopic: topic) else {
            networkingInteractor.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: topic))
            return
        }
        guard session.peerIsController else {
            networkingInteractor.respondError(for: payload, reason: .unauthorizedUpdateExpiryRequest)
            return
        }
        do {
            try session.updateExpiry(to: updateExpiryParams.expiry)
        } catch {
            print(error)
            networkingInteractor.respondError(for: payload, reason: .invalidUpdateExpiryRequest)
            return
        }
        sessionStore.setSession(session)
        networkingInteractor.respondSuccess(for: payload)
        onExpiryUpdate?(session.topic, session.expiryDate)
    }
}
