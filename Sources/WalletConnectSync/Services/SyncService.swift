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
    private let historyStore: SyncHistoryStore
    private let logger: ConsoleLogging

    /// `account` to `Record` keyValue store
    private let indexStore: SyncIndexStore

    init(networkInteractor: NetworkInteracting, derivationService: SyncDerivationService, signatureStore: SyncSignatureStore, indexStore: SyncIndexStore, historyStore: SyncHistoryStore, logger: ConsoleLogging) {
        self.networkInteractor = networkInteractor
        self.derivationService = derivationService
        self.signatureStore = signatureStore
        self.indexStore = indexStore
        self.historyStore = historyStore
        self.logger = logger

        setupSubscriptions()
    }

    func create(account: Account, store: String) async throws {
        if let _ = try? indexStore.getRecord(account: account, name: store) {
            return
        }

        let topic = try derivationService.deriveTopic(account: account, store: store)
        indexStore.set(topic: topic, name: store, account: account)
    }

    func subscribe(account: Account, store: String) async throws {
        guard let record = try? indexStore.getRecord(account: account, name: store) else {
            throw Errors.recordNotFoundForAccount
        }
        try await networkInteractor.subscribe(topic: record.topic)
    }

    func set<Object: DatabaseObject>(account: Account, store: String, object: Object) async throws {
        let protocolMethod = SyncSetMethod()
        let params = StoreSet(key: object.databaseId, value: try object.json())
        let rpcid = RPCID()
        let request = RPCRequest(method: protocolMethod.method, params: params, rpcid: rpcid)
        let record = try indexStore.getRecord(account: account, name: store)

        try await networkInteractor.request(request, topic: record.topic, protocolMethod: protocolMethod)

        historyStore.set(rpcid: rpcid.integer, topic: record.topic)

        logger.debug("Did set value for \(store). Sent on \(record.topic). Object: \n\(object)\n")
    }

    func delete(account: Account, store: String, key: String) async throws {
        let protocolMethod = SyncDeleteMethod()
        let rpcid = RPCID()
        let request = RPCRequest(method: protocolMethod.method, params: ["key": key], rpcid: rpcid)
        let record = try indexStore.getRecord(account: account, name: store)

        try await networkInteractor.request(request, topic: record.topic, protocolMethod: protocolMethod)

        historyStore.set(rpcid: rpcid.integer, topic: record.topic)

        logger.debug("Did delete value for \(store). Sent on: \(record.topic). Key: \n\(key)\n")
    }
}

private extension SyncService {

    enum Errors: Error {
        case recordNotFoundForAccount
    }

    func setupSubscriptions() {
        networkInteractor.requestSubscription(on: SyncSetMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<StoreSet>) in
                if historyStore.update(topic: payload.topic, rpcid: payload.id) {
                    self.updateSubject.send((payload.topic, .set(payload.request)))
                }
            }
            .store(in: &publishers)

        networkInteractor.requestSubscription(on: SyncDeleteMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<StoreDelete>) in
                if historyStore.update(topic: payload.topic, rpcid: payload.id) {
                    self.updateSubject.send((payload.topic, .delete(payload.request)))
                }
            }
            .store(in: &publishers)
    }
}
