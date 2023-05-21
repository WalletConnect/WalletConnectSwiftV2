import UIKit
import Combine
import WalletConnectPush

final class PushMessagesPresenter: ObservableObject {

    private let interactor: PushMessagesInteractor
    private let router: PushMessagesRouter
    private var disposeBag = Set<AnyCancellable>()
    
    @Published var pushMessages: [PushMessageViewModel] = []

    init(interactor: PushMessagesInteractor, router: PushMessagesRouter) {
        defer { reloadPushMessages() }
        self.interactor = interactor
        self.router = router
    }
    
    func deletePushMessage(at indexSet: IndexSet) {
        if let index = indexSet.first {
            interactor.deletePushMessage(id: pushMessages[index].id)
        }
        reloadPushMessages()
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

    func reloadPushMessages() {
        self.pushMessages = interactor.getPushMessages()
            .sorted {
                // Most recent first
                $0.publishedAt > $1.publishedAt
            }
            .map { pushMessageRecord in
                PushMessageViewModel(pushMessageRecord: pushMessageRecord)
            }
        
        interactor.pushMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPushMessage in
                let newMessageViewModel = PushMessageViewModel(pushMessageRecord: newPushMessage)
                guard let index = self?.pushMessages.firstIndex(
                    where: { $0.pushMessageRecord.publishedAt > newPushMessage.publishedAt }
                ) else {
                    self?.pushMessages.append(newMessageViewModel)
                    return
                }
                self?.pushMessages.insert(newMessageViewModel, at: index)
            }
            .store(in: &disposeBag)
    }
}

