import UIKit
import Combine
import Chat

final class ChatPresenter: ObservableObject {

    private let thread: Chat.Thread
    private let interactor: ChatInteractor
    private let router: ChatRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published var messages: [MessageViewModel] = []
    @Published var input: String = .empty

    init(thread: Chat.Thread, interactor: ChatInteractor, router: ChatRouter) {
        self.thread = thread
        self.interactor = interactor
        self.router = router
    }

    @MainActor
    func setupInitialState() async {
        await loadMessages()

        for await _ in interactor.messagesSubscription() {
            await loadMessages()
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
        return "Chat"
    }
}

// MARK: Privates

private extension ChatPresenter {

    func loadMessages() async {
        let messages = await interactor.getMessages(thread: thread)
        self.messages = messages.sorted(by: { $0.timestamp < $1.timestamp })
            .map { MessageViewModel(message: $0, thread: thread) }
    }

    @MainActor
    func sendMessage() async {
        try! await interactor.sendMessage(topic: thread.topic, message: input)
        input = .empty
    }
}
