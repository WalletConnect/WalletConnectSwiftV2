import UIKit
import Combine
import WalletConnectNotify

final class PushMessagesPresenter: ObservableObject {

    private let interactor: PushMessagesInteractor
    private let router: PushMessagesRouter
    private var disposeBag = Set<AnyCancellable>()
    
    @Published private var pushMessages: [NotifyMessageRecord] = []

    var messages: [PushMessageViewModel] {
        return pushMessages
            .sorted { $0.publishedAt > $1.publishedAt }
            .map { PushMessageViewModel(pushMessageRecord: $0) }
    }

    init(interactor: PushMessagesInteractor, router: PushMessagesRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
    }
    
    func deletePushMessage(at indexSet: IndexSet) {
        if let index = indexSet.first {
            interactor.deletePushMessage(id: pushMessages[index].id)
        }
    }
}

// MARK: SceneViewModel

extension PushMessagesPresenter: SceneViewModel {
    var sceneTitle: String? {
        return interactor.subscription.metadata.name
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension PushMessagesPresenter {

    func setupInitialState() {
        pushMessages = interactor.getPushMessages()

        interactor.messagesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] messages in
                pushMessages = interactor.getPushMessages()
            }
            .store(in: &disposeBag)
    }
}

