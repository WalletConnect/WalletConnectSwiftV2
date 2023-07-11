import Foundation

final class PushSubscriptionStoreDelegate {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
    }

    func onUpdate(_ subscription: PushSubscription) {
        Task(priority: .high) {
            let symmetricKey = try SymmetricKey(hex: subscription.symKey)
            try kms.setSymmetricKey(symmetricKey, for: subscription.topic)
            try await networkingInteractor.subscribe(topic: subscription.topic)
        }
    }

    func onDelete(_ subscription: PushSubscription, pushStorage: PushStorage) {
        Task(priority: .high) {
            kms.deleteSymmetricKey(for: subscription.topic)
            networkingInteractor.unsubscribe(topic: subscription.topic)
            pushStorage.deleteMessages(topic: subscription.topic)
        }
    }
}
