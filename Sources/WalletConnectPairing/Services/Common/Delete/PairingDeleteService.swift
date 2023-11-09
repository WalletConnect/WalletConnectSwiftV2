import Foundation

public final class PairingDeleteService {
    private let deleteRequester: DeleteRequester
    private let deleteRequestSubscriber: DeleteRequestSubscriber
    private let deleteResponseSubscriber: DeleteResponseSubscriber
    
    public var onDeleteRequestSubscriberResponse: ((String) -> Void)? {
        get {
            return deleteRequestSubscriber.onResponse
        }
        set {
            deleteRequestSubscriber.onResponse = newValue
        }
    }
    
    public var onDeleteResponseSubscriberResponse: ((String) -> Void)? {
        get {
            return deleteResponseSubscriber.onResponse
        }
        set {
            deleteResponseSubscriber.onResponse = newValue
        }
    }
    
    public init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        pairingStorage: WCPairingStorage,
        logger: ConsoleLogging
    ) {
        let protocolMethod = PairingProtocolMethod.delete
        self.deleteRequester = DeleteRequester(networkingInteractor: networkingInteractor, method: protocolMethod, kms: kms, pairingStorage: pairingStorage, logger: logger)
        self.deleteRequestSubscriber = DeleteRequestSubscriber(networkingInteractor: networkingInteractor, method: protocolMethod, logger: logger)
        self.deleteResponseSubscriber = DeleteResponseSubscriber(networkingInteractor: networkingInteractor, method: protocolMethod, logger: logger)
    }
    
    public func delete(topic: String) async throws {
        try await deleteRequester.delete(topic: topic)
    }
}
