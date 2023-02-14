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
        self.thread = thread
        self.interactor = interactor
        self.router = router
    }

    @MainActor
    func setupInitialState() async {
        messages = interactor.getMessages(thread: thread)

        for await newMessages in interactor.messagesSubscription(thread: thread) {
            messages = newMessages
        }
    }

    func didPressSend() {
        Task(priority: .userInitiated) {
            await sendMessage()
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

    @MainActor
    func sendMessage() async {
        try! await interactor.sendMessage(topic: thread.topic, message: input)
        input = .empty
    }
}
