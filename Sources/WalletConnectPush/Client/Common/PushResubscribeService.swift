import Foundation
import WalletConnectNetworking
import Combine

final class PushResubscribeService {

    private var publishers = Set<AnyCancellable>()

    private let networkInteractor: NetworkInteracting
    private let subscriptionsStorage: CodableStore<PushSubscription>

    init(networkInteractor: NetworkInteracting, subscriptionsStorage: CodableStore<PushSubscription>) {
        self.networkInteractor = networkInteractor
        self.subscriptionsStorage = subscriptionsStorage
        setUpResubscription()
    }

    func setUpResubscription() {
        networkInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                subscriptionsStorage.getAll()
                    .forEach { subscription in
                        Task(priority: .high) { try await networkInteractor.subscribe(topic: subscription.topic) }
                    }
            }
            .store(in: &publishers)
    }
}
