import UIKit
import Combine

final class ChatPresenter: ObservableObject {

    private let topic: String
    private let interactor: ChatInteractor
    private let router: ChatRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published var messages: [MessageViewModel] = []
    @Published var input: String = .empty

    init(topic: String, interactor: ChatInteractor, router: ChatRouter) {
        self.topic = topic
        self.interactor = interactor
        self.router = router
    }

    @MainActor
    func setupInitialState() async {
        let account = await interactor.getCurrentAccount()

        for await messages in interactor.getMessages(topic: topic) {
            self.messages = messages
                .sorted(by: { $0.timestamp < $1.timestamp })
                .map { MessageViewModel(message: $0, currentAccount: account) }
        }
    }

    func didPressSend() {
        sendMessage()
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

    func sendMessage() {
        Task {
            try! await interactor.sendMessage(text: input)
            input = .empty
        }
    }
}
