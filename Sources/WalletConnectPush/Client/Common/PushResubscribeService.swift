import Foundation
import WalletConnectNetworking
import Combine

final class PushResubscribeService {

    private var publishers = Set<AnyCancellable>()

    private let networkInteractor: NetworkInteracting
    private let subscriptionsStorage: SyncStore<PushSubscription>

    init(networkInteractor: NetworkInteracting, subscriptionsStorage: SyncStore<PushSubscription>) {
        self.networkInteractor = networkInteractor
        self.subscriptionsStorage = subscriptionsStorage
        setUpResubscription()
    }

    func setUpResubscription() {
        networkInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                let topics = subscriptionsStorage.getAll().map{$0.topic}
                Task(priority: .high) {
                    try await networkInteractor.batchSubscribe(topics: topics)
                }
            }
            .store(in: &publishers)
    }
}
