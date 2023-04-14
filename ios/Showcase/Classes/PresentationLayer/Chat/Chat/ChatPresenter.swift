import UIKit
import Combine
import WalletConnectChat

final class ChatPresenter: ObservableObject {

    private let thread: WalletConnectChat.Thread
    private let interactor: ChatInteractor
    private let router: ChatRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published private var messages: [Message] = []
    @Published var input: String = .empty

    var messageViewModels: [MessageViewModel] {
        return messages.sorted(by: { $0.timestamp < $1.timestamp })
            .map { MessageViewModel(message: $0, thread: thread) }
    }

    init(thread: WalletConnectChat.Thread, interactor: ChatInteractor, router: ChatRouter) {
        defer { setupInitialState() }
        self.thread = thread
        self.interactor = interactor
        self.router = router
    }

    func didPressSend() {
        Task(priority: .userInitiated) {
            try await sendMessage()
        }
    }
}

// MARK: SceneViewModel

extension ChatPresenter: SceneViewModel {

    var sceneTitle: String? {
        return thread.peerAccount.address
    }
}

// MARK: Privates

private extension ChatPresenter {

    func setupInitialState() {
        messages = interactor.getMessages(thread: thread)

        interactor.messagesSubscription(thread: thread)
            .sink { [unowned self] messages in
                self.messages = messages
            }.store(in: &disposeBag)
    }

    @MainActor
    func sendMessage() async throws {
        try await interactor.sendMessage(topic: thread.topic, message: input)
        input = .empty
    }
}
