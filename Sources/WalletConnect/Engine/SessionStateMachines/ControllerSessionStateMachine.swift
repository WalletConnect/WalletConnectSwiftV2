
import Foundation
import WalletConnectUtils
import WalletConnectKMS

final class ControllerSessionStateMachine: SessionStateMachineValidating {
    
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
        relayer.onResponse = { [weak self] in
            self?.handleResponse($0)
        }
    }
    
    func updateMethods(topic: String, methods: Set<String>) throws {
        guard var session = sequencesStore.getSequence(forTopic: topic) else {
            throw WalletConnectError.noSessionMatchingTopic(topic)
        }
        guard session.acknowledged else {
            throw WalletConnectError.sessionNotAcknowledged(topic)
        }
        guard session.selfIsController else {
            throw WalletConnectError.unauthorizedNonControllerCall
        }
        guard validateMethods(methods) else {
            throw WalletConnectError.invalidMethod
        }
        session.updateMethods(methods)
        sequencesStore.setSequence(session)
        relayer.request(.wcSessionUpdateMethods(SessionType.UpdateMethodsParams(methods: methods)), onTopic: topic)
    }
    
    // MARK: - Handle Response
    
    private func handleResponse(_ response: WCResponse) {
        switch response.requestParams {
        case .sessionUpdateMethods:
            handleUpdateMethodsResponse(topic: response.topic, result: response.result)
        default:
            break
        }
    }
    
    private func handleUpdateMethodsResponse(topic: String, result: JsonRpcResult) {
        guard let session = sequencesStore.getSequence(forTopic: topic) else {
            return
        }
        switch result {
        case .response:
            //TODO - state sync
            onMethodsUpdate?(session.topic, session.methods)
        case .error:
            //TODO - state sync
            logger.error("Peer failed to upgrade permissions.")
        }
    }
}
