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

    func onDelete(_ id: String) {

    }
}
