
import Foundation
import WalletConnectUtils
import WalletConnectKMS

final class NonControllerSessionStateMachine: SessionStateMachineValidating {
    
    var onMethodsUpdate: ((String, Set<String>)->())?
    
    private let sequencesStore: SessionSequenceStorage
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging

    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         subscriber: WCSubscribing,
         sequencesStore: SessionSequenceStorage,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String = String.generateTopic) {
        self.relayer = relay
        self.kms = kms
        self.wcSubscriber = subscriber
        self.sequencesStore = sequencesStore
        self.logger = logger
        setUpWCRequestHandling()
    }
    
    private func setUpWCRequestHandling() {
        wcSubscriber.onReceivePayload = { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .sessionUpdateMethods(let updateParams):
                wcSessionUpdateMethods(payload: subscriptionPayload, updateParams: updateParams)
            default:
                logger.warn("Warning: Session Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }
    }
    
    private func wcSessionUpdateMethods(payload: WCRequestSubscriptionPayload, updateParams: SessionType.UpdateMethodsParams) {
        guard validateMethods(updateParams.methods) else {
            relayer.respondError(for: payload, reason: .invalidUpgradeRequest(context: .session))
            return
        }
        guard var session = sequencesStore.getSequence(forTopic: payload.topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
            return
        }
        guard session.peerIsController else {
            relayer.respondError(for: payload, reason: .unauthorizedUpdateRequest(context: .session))
            return
        }
        session.updateMethods(updateParams.methods)
        sequencesStore.setSequence(session)
        relayer.respondSuccess(for: payload)
        onMethodsUpdate?(session.topic, updateParams.methods)
    }
}

protocol SessionStateMachineValidating {
    func validateMethods(_ methods: Set<String>) -> Bool
}

extension SessionStateMachineValidating {
    func validateMethods(_ methods: Set<String>) -> Bool {
        for method in methods {
            if method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }
    }
}
