
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class NonControllerSessionStateMachine: SessionStateMachineValidating {
    
    var onMethodsUpdate: ((String, Set<String>)->())?
    
    private let sequencesStore: SessionSequenceStorage
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging

    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         sequencesStore: SessionSequenceStorage,
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
                wcSessionUpdateMethods(payload: subscriptionPayload, updateParams: updateParams)
            default:
                logger.warn("Warning: Session Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }.store(in: &publishers)
    }
    
    private func wcSessionUpdateMethods(payload: WCRequestSubscriptionPayload, updateParams: SessionType.UpdateMethodsParams) {
        guard validateMethods(updateParams.methods) else {
            relayer.respondError(for: payload, reason: .invalidUpdateMethodsRequest)
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
