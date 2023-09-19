import UIKit
import Combine
import WalletConnectNotify

final class PushMessagesPresenter: ObservableObject {

    private let subscription: NotifySubscription
    private let interactor: PushMessagesInteractor
    private let router: PushMessagesRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published private var pushMessages: [NotifyMessageRecord] = []

    var subscriptionViewModel: SubscriptionsViewModel {
        return SubscriptionsViewModel(subscription: subscription)
    }

    var messages: [PushMessageViewModel] {
        return pushMessages
            .sorted { $0.publishedAt > $1.publishedAt }
            .map { PushMessageViewModel(pushMessageRecord: $0) }
    }

    init(subscription: NotifySubscription, interactor: PushMessagesInteractor, router: PushMessagesRouter) {
        defer { setupInitialState() }
        self.subscription = subscription
        self.interactor = interactor
        self.router = router
        setUpMessagesRefresh()
    }

    private func setUpMessagesRefresh() {
        Timer.publish(every: 10.0, on: .main, in: .default)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.pushMessages = self.interactor.getPushMessages()
            }).store(in: &disposeBag)
    }

    func deletePushMessage(at indexSet: IndexSet) {
        if let index = indexSet.first {
            interactor.deletePushMessage(id: pushMessages[index].id)
        }
    }

    func unsubscribe() {
        interactor.deleteSubscription(subscription)
        router.dismiss()
    }

    @objc func preferencesDidPress() {
        router.presentPreferences(subscription: subscription)
    }
}

// MARK: SceneViewModel

extension PushMessagesPresenter: SceneViewModel {

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .never
    }

    var navigationBarStyle: NavigationBarStyle {
        return .clear
    }

    var rightBarButtonItem: UIBarButtonItem? {
        return UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(preferencesDidPress)
        )
    }
}

// MARK: Privates

private extension PushMessagesPresenter {

    func setupInitialState() {
        pushMessages = interactor.getPushMessages()

        interactor.messagesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                guard let self = self else { return }
                self.pushMessages = self.interactor.getPushMessages()
            }
            .store(in: &disposeBag)
    }
}

