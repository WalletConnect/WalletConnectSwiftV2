import Foundation
import Combine

public class NotifyClient {

    private var publishers = Set<AnyCancellable>()

    public var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return notifyStorage.subscriptionsPublisher
    }

    public var messagesPublisher: AnyPublisher<[NotifyMessageRecord], Never> {
        return notifyStorage.messagesPublisher
    }

    public var logsPublisher: AnyPublisher<Log, Never> {
        return logger.logsPublisher
    }

    private let deleteNotifySubscriptionRequester: DeleteNotifySubscriptionRequester
    private let notifySubscribeRequester: NotifySubscribeRequester

    public let logger: ConsoleLogging

    private let keyserverURL: URL
    private let pushClient: PushClient
    private let identityClient: IdentityClient
    private let notifyStorage: NotifyStorage
    private let notifyAccountProvider: NotifyAccountProvider
    private let notifyMessageSubscriber: NotifyMessageSubscriber
    private let resubscribeService: NotifyResubscribeService
    private let notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber
    private let notifyUpdateRequester: NotifyUpdateRequester
    private let notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber
    private let subscriptionsAutoUpdater: SubscriptionsAutoUpdater
    private let notifyWatchSubscriptionsResponseSubscriber: NotifyWatchSubscriptionsResponseSubscriber
    private let notifyWatcherAgreementKeysProvider: NotifyWatcherAgreementKeysProvider
    private let notifySubscriptionsChangedRequestSubscriber: NotifySubscriptionsChangedRequestSubscriber
    private let subscriptionWatcher: SubscriptionWatcher

    init(logger: ConsoleLogging,
         keyserverURL: URL,
         kms: KeyManagementServiceProtocol,
         identityClient: IdentityClient,
         pushClient: PushClient,
         notifyMessageSubscriber: NotifyMessageSubscriber,
         notifyStorage: NotifyStorage,
         deleteNotifySubscriptionRequester: DeleteNotifySubscriptionRequester,
         resubscribeService: NotifyResubscribeService,
         notifySubscribeRequester: NotifySubscribeRequester,
         notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber,
         notifyUpdateRequester: NotifyUpdateRequester,
         notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber,
         notifyAccountProvider: NotifyAccountProvider,
         subscriptionsAutoUpdater: SubscriptionsAutoUpdater,
         notifyWatchSubscriptionsResponseSubscriber: NotifyWatchSubscriptionsResponseSubscriber,
         notifyWatcherAgreementKeysProvider: NotifyWatcherAgreementKeysProvider,
         notifySubscriptionsChangedRequestSubscriber: NotifySubscriptionsChangedRequestSubscriber,
         subscriptionWatcher: SubscriptionWatcher
    ) {
        self.logger = logger
        self.keyserverURL = keyserverURL
        self.pushClient = pushClient
        self.identityClient = identityClient
        self.notifyMessageSubscriber = notifyMessageSubscriber
        self.notifyStorage = notifyStorage
        self.deleteNotifySubscriptionRequester = deleteNotifySubscriptionRequester
        self.resubscribeService = resubscribeService
        self.notifySubscribeRequester = notifySubscribeRequester
        self.notifySubscribeResponseSubscriber = notifySubscribeResponseSubscriber
        self.notifyUpdateRequester = notifyUpdateRequester
        self.notifyUpdateResponseSubscriber = notifyUpdateResponseSubscriber
        self.notifyAccountProvider = notifyAccountProvider
        self.subscriptionsAutoUpdater = subscriptionsAutoUpdater
        self.notifyWatchSubscriptionsResponseSubscriber = notifyWatchSubscriptionsResponseSubscriber
        self.notifyWatcherAgreementKeysProvider = notifyWatcherAgreementKeysProvider
        self.notifySubscriptionsChangedRequestSubscriber = notifySubscriptionsChangedRequestSubscriber
        self.subscriptionWatcher = subscriptionWatcher
    }

    public func prepareRegistration(account: Account, domain: String, allApps: Bool = true) async throws -> IdentityRegistrationParams {
        return try await identityClient.prepareRegistration(
            account: account,
            domain: domain,
            statement: makeStatement(allApps: allApps),
            resources: [keyserverURL.absoluteString]
        )
    }

    public func register(params: IdentityRegistrationParams, signature: CacaoSignature) async throws {
        try await identityClient.register(params: params, signature: signature)
        notifyAccountProvider.setAccount(try params.account)
        try await subscriptionWatcher.start()
    }

    public func unregister(account: Account) async throws {
        try await identityClient.unregister(account: account)
        notifyWatcherAgreementKeysProvider.removeAgreement(account: account)
        try notifyStorage.clearDatabase(account: account)
        notifyAccountProvider.logout()
        subscriptionWatcher.stop()
    }

    public func setLogging(level: LoggingLevel) {
        logger.setLogging(level: level)
    }

    public func subscribe(appDomain: String, account: Account) async throws {
        try await notifySubscribeRequester.subscribe(appDomain: appDomain, account: account)
    }

    public func update(topic: String, scope: Set<String>) async throws {
        try await notifyUpdateRequester.update(topic: topic, scope: scope)
    }

    public func getActiveSubscriptions(account: Account) -> [NotifySubscription] {
        return notifyStorage.getSubscriptions(account: account)
    }

    public func getMessageHistory(topic: String) -> [NotifyMessageRecord] {
        notifyStorage.getMessages(topic: topic)
    }

    public func deleteSubscription(topic: String) async throws {
        try await deleteNotifySubscriptionRequester.delete(topic: topic)
    }

    public func deleteNotifyMessage(id: String) {
        try? notifyStorage.deleteMessage(id: id)
    }

    public func register(deviceToken: Data, enableEncrypted: Bool = false) async throws {
        try await pushClient.register(deviceToken: deviceToken, enableEncrypted: enableEncrypted)
    }

    public func isIdentityRegistered(account: Account) -> Bool {
        return identityClient.isIdentityRegistered(account: account)
    }

    public func subscriptionsPublisher(account: Account) -> AnyPublisher<[NotifySubscription], Never> {
        return notifyStorage.subscriptionsPublisher(account: account)
    }

    public func messagesPublisher(topic: String) -> AnyPublisher<[NotifyMessageRecord], Never> {
        return notifyStorage.messagesPublisher(topic: topic)
    }
}

private extension NotifyClient {

    func makeStatement(allApps: Bool) -> String {
        switch allApps {
        case false:
            return "I further authorize this app to send me notifications. Read more at https://walletconnect.com/notifications"
        case true:
            return "I further authorize this app to view and manage my notifications for ALL apps. Read more at https://walletconnect.com/notifications"
        }
    }
}

#if targetEnvironment(simulator)
extension NotifyClient {

    public var subscriptionChangedPublisher: AnyPublisher<[NotifySubscription], Never> {
        return notifySubscriptionsChangedRequestSubscriber.subscriptionChangedPublisher
    }

    public func register(deviceToken: String) async throws {
        try await pushClient.register(deviceToken: deviceToken)
    }
}
#endif

