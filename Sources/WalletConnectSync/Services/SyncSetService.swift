import Foundation
import Combine

final class SyncSetService {

    private var publishers: Set<AnyCancellable> = []

    private let networkInteractor: NetworkInteracting
    private let derivationService: SyncDerivationService
    private let storage: SyncStorage

    init(networkInteractor: NetworkInteracting, derivationService: SyncDerivationService, storage: SyncStorage) {
        self.networkInteractor = networkInteractor
        self.derivationService = derivationService
        self.storage = storage

        setupSubscriptions()
    }

    func set(account: Account, store: String, key: String, value: String) async throws {
        let protocolMethod = SyncSetMethod()
        let request = RPCRequest(method: protocolMethod.method, params: ["key": key, "value": value])
        let topic = try derivationService.deriveTopic(account: account, store: store)
        try await networkInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        let set = StoreSet(id: request.id!.integer, key: key, value: value)
        storage.set(update: .set(set), topic: topic, store: store, for: account)
    }
}

private extension SyncSetService {

    func setupSubscriptions() {

    }

    func handleSetResponse() {
        networkInteractor.requestSubscription(on: SyncSetMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<StoreSet>) in
                storage.set(update: payload.request, topic: payload.topic, store: <#T##String#>, for: <#T##Account#>)

            }
            .store(in: &publishers)
    }
}
