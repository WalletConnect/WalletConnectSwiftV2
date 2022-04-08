
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class NonControllerSessionStateMachine: SessionStateMachineValidating {
    
    var onMethodsUpdate: ((String, Set<String>)->())?
    var onEventsUpdate: ((String, Set<String>)->())?
    
    private let sequencesStore: WCSessionStorage
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging

    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         sequencesStore: WCSessionStorage,
         logger: ConsoleLogging) {
        self.relayer = relay
        self.kms = kms
        self.sequencesStore = sequencesStore
        self.logger = logger
        setUpWCRequestHandling()
    }
    
    private func setUpWCRequestHandling() {
        relayer.wcRequestPublisher.sink { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .sessionUpdateMethods(let updateParams):
                onSessionUpdateMethodsRequest(payload: subscriptionPayload, updateParams: updateParams)
            case .sessionUpdateEvents(let updateParams):
                onSessionUpdateEventsRequest(payload: subscriptionPayload, updateParams: updateParams)
            default:
                logger.warn("Warning: Session Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }.store(in: &publishers)
    }
    
    private func onSessionUpdateMethodsRequest(payload: WCRequestSubscriptionPayload, updateParams: SessionType.UpdateMethodsParams) {
        do {
            try validateMethods(updateParams.methods)
        } catch {
            relayer.respondError(for: payload, reason: .invalidUpdateMethodsRequest)
            return
        }
        guard var session = sequencesStore.getSequence(forTopic: payload.topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
            return
        }
        guard session.peerIsController else {
            relayer.respondError(for: payload, reason: .unauthorizedUpdateMethodsRequest)
            return
        }
        session.updateMethods(updateParams.methods)
        sequencesStore.setSequence(session)
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
        guard var session = sequencesStore.getSequence(forTopic: payload.topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
            return
        }
        guard session.peerIsController else {
            relayer.respondError(for: payload, reason: .unauthorizedUpdateEventsRequest)
            return
        }
        session.updateEvents(updateParams.events)
        sequencesStore.setSequence(session)
        relayer.respondSuccess(for: payload)
        onEventsUpdate?(session.topic, updateParams.events)
    }
}
