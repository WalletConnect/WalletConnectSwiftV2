import Foundation
import Combine

final class SyncService {

    private let updateSubject = PassthroughSubject<(String, StoreUpdate), Never>()

    var updatePublisher: AnyPublisher<(String, StoreUpdate), Never> {
        return updateSubject.eraseToAnyPublisher()
    }

    private var publishers: Set<AnyCancellable> = []

    private let networkInteractor: NetworkInteracting
    private let derivationService: SyncDerivationService
    private let signatureStore: SyncSignatureStore
    private let logger: ConsoleLogging

    /// `account` to `Record` keyValue store
    private let indexStore: SyncIndexStore

    init(networkInteractor: NetworkInteracting, derivationService: SyncDerivationService, signatureStore: SyncSignatureStore, indexStore: SyncIndexStore, logger: ConsoleLogging) {
        self.networkInteractor = networkInteractor
        self.derivationService = derivationService
        self.signatureStore = signatureStore
        self.indexStore = indexStore
        self.logger = logger

        setupSubscriptions()
    }

    func set<Object: SyncObject>(account: Account, store: String, object: Object) async throws {
        let protocolMethod = SyncSetMethod()
        let params = StoreSet(key: object.syncId, value: object)
        let request = RPCRequest(method: protocolMethod.method, params: params)
        let record = try indexStore.getRecord(account: account, name: store)
        try await networkInteractor.request(request, topic: record.topic, protocolMethod: protocolMethod)

        logger.debug("Did set value for \(store). Sent on \(record.topic). Object: \n\(object)\n")
    }

    func delete(account: Account, store: String, key: String) async throws {
        let protocolMethod = SyncDeleteMethod()
        let request = RPCRequest(method: protocolMethod.method, params: ["key": key])
        let record = try indexStore.getRecord(account: account, name: store)
        try await networkInteractor.request(request, topic: record.topic, protocolMethod: protocolMethod)

        logger.debug("Did delete value for \(store). Sent on: \(record.topic). Key: \n\(key)\n")
    }

    func create(account: Account, store: String) async throws {
        let topic = try getTopic(for: account, store: store)
        try await networkInteractor.subscribe(topic: topic)

        logger.debug("Store \(store) created. Subscribed on: \(topic)")
    }
}

private extension SyncService {

    enum Errors: Error {
        case recordNotFoundForAccount
    }

    func setupSubscriptions() {
        networkInteractor.requestSubscription(on: SyncSetMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<AnyCodable>) in
                self.updateSubject.send((payload.topic, .set(payload.request)))
            }
            .store(in: &publishers)

        networkInteractor.requestSubscription(on: SyncDeleteMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<StoreDelete>) in
                self.updateSubject.send((payload.topic, .delete(payload.request.key)))
            }
            .store(in: &publishers)
    }

    func getTopic(for account: Account, store: String) throws -> String {
        if let record = try? indexStore.getRecord(account: account, name: store) {
            return record.topic
        }

        let topic = try derivationService.deriveTopic(account: account, store: store)
        indexStore.set(topic: topic, name: store, account: account)
        return topic
    }
}
