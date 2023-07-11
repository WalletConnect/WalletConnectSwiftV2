import Foundation

final class ReceiviedInviteStatusDelegate {

    func onInitialization() async throws {

    }

    func onUpdate(_ status: ReceivedInviteStatus, storage: ChatStorage, account: Account) {
        guard status.status == .rejected else { return }

        if let receivedInvite = storage.getReceivedInvite(id: status.id) {
            storage.reject(receivedInvite: receivedInvite, account: account)
        }
    }

    func onDelete(_ status: ReceivedInviteStatus) {

    }
}
