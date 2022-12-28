import Foundation
import Combine
import WalletConnectChat

final class ChatClientRequestSubscriper {

    private var publishers: Set<AnyCancellable> = []

    private let chatClient: ChatClient

    var onRequest: ((ChatClientRequest) -> Void)?

    init(chatClient: ChatClient) {
        self.chatClient = chatClient

        setupSubscriptions()
    }

    func setupSubscriptions() {
        chatClient.invitePublisher
            .sink { [unowned self] invite in
                onRequest?(.chatInvite(invite: invite))
            }.store(in: &publishers)
    }
}
