import Foundation

final class PushSubscriptionStoreDelegate {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let groupKeychainStorage: KeychainStorageProtocol

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol, groupKeychainStorage: KeychainStorageProtocol) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.groupKeychainStorage = groupKeychainStorage
    }

    func onUpdate(_ subscription: PushSubscription) {
        Task(priority: .high) {
            let symmetricKey = try SymmetricKey(hex: subscription.symKey)
            try kms.setSymmetricKey(symmetricKey, for: subscription.topic)
            try groupKeychainStorage.add(symmetricKey, forKey: subscription.topic)
            try await networkingInteractor.subscribe(topic: subscription.topic)
        }
    }

    func onDelete(_ subscription: PushSubscription, pushStorage: PushStorage) {
        Task(priority: .high) {
            kms.deleteSymmetricKey(for: subscription.topic)
            try? groupKeychainStorage.delete(key: subscription.topic)
            networkingInteractor.unsubscribe(topic: subscription.topic)
            pushStorage.deleteMessages(topic: subscription.topic)
        }
    }
}
