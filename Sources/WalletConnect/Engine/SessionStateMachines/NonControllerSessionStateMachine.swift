
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class NonControllerSessionStateMachine: SessionStateMachineValidating {
    
    var onSessionUpdateAccounts: ((String, Set<Account>)->())?
    var onMethodsUpdate: ((String, Set<String>)->())?
    var onEventsUpdate: ((String, Set<String>)->())?
    var onSessionExpiry: ((Session) -> ())?
    
    private let sessionStore: WCSessionStorage
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging

    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         sessionStore: WCSessionStorage,
         logger: ConsoleLogging) {
        self.relayer = relay
        self.kms = kms
        self.sessionStore = sessionStore
        self.logger = logger
        setUpWCRequestHandling()
    }
    
    private func setUpWCRequestHandling() {
        relayer.wcRequestPublisher.sink { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .sessionUpdateAccounts(let updateParams):
                onSessionUpdateAccounts(payload: subscriptionPayload, updateParams: updateParams)
            case .sessionUpdateMethods(let updateParams):
                onSessionUpdateMethodsRequest(payload: subscriptionPayload, updateParams: updateParams)
            case .sessionUpdateEvents(let updateParams):
                onSessionUpdateEventsRequest(payload: subscriptionPayload, updateParams: updateParams)
            case .sessionUpdateExpiry(let updateExpiryParams):
                onSessionUpdateExpiry(subscriptionPayload, updateExpiryParams: updateExpiryParams)
            default:
                logger.warn("Warning: Session Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }.store(in: &publishers)
    }
    
    private func onSessionUpdateAccounts(payload: WCRequestSubscriptionPayload, updateParams: SessionType.UpdateAccountsParams) {
        if !updateParams.isValidParam {
            relayer.respondError(for: payload, reason: .invalidUpdateAccountsRequest)
            return
        }
        let topic = payload.topic
        guard var session = sessionStore.getSession(forTopic: topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: topic))
                  return
              }
        guard session.peerIsController else {
            relayer.respondError(for: payload, reason: .unauthorizedUpdateAccountRequest)
            return
        }
        session.updateAccounts(updateParams.getAccounts())
        sessionStore.setSession(session)
        relayer.respondSuccess(for: payload)
        onSessionUpdateAccounts?(topic, updateParams.getAccounts())
    }
    
    private func onSessionUpdateMethodsRequest(payload: WCRequestSubscriptionPayload, updateParams: SessionType.UpdateMethodsParams) {
        do {
            try validateMethods(updateParams.methods)
        } catch {
            relayer.respondError(for: payload, reason: .invalidUpdateMethodsRequest)
            return
        }
        guard var session = sessionStore.getSession(forTopic: payload.topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
            return
        }
        guard session.peerIsController else {
            relayer.respondError(for: payload, reason: .unauthorizedUpdateMethodsRequest)
            return
        }
        session.updateMethods(updateParams.methods)
        sessionStore.setSession(session)
        relayer.respondSuccess(for: payload)
        onMethodsUpdate?(session.topic, updateParams.methods)
    }
    
    private func onSessionUpdateEventsRequest(payload: WCRequestSubscriptionPayload, updateParams: SessionType.UpdateEventsParams) {
        do {
            try validateEvents(updateParams.events)
        } catch {
            relayer.respondError(for: payload, reason: .invalidUpdateEventsRequest)
            return
        }
        guard var session = sessionStore.getSession(forTopic: payload.topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
            return
        }
        guard session.peerIsController else {
            relayer.respondError(for: payload, reason: .unauthorizedUpdateEventsRequest)
            return
        }
        session.updateEvents(updateParams.events)
        sessionStore.setSession(session)
        relayer.respondSuccess(for: payload)
        onEventsUpdate?(session.topic, updateParams.events)
    }
    
    private func onSessionUpdateExpiry(_ payload: WCRequestSubscriptionPayload, updateExpiryParams: SessionType.UpdateExpiryParams) {
        let topic = payload.topic
        guard var session = sessionStore.getSession(forTopic: topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: topic))
            return
        }
        guard session.peerIsController else {
            relayer.respondError(for: payload, reason: .unauthorizedUpdateExpiryRequest)
            return
        }
        do {
            try session.updateExpiry(to: updateExpiryParams.expiry)
        } catch {
            relayer.respondError(for: payload, reason: .invalidUpdateExpiryRequest)
            return
        }
        sessionStore.setSession(session)
        relayer.respondSuccess(for: payload)
        onSessionExpiry?(session.publicRepresentation())
    }
}
