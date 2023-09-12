import Foundation
import Combine

final class NotifyClientRequestSubscriber {

    private var publishers: Set<AnyCancellable> = []

    private let client: NotifyClient
    private let logger: ConsoleLogging

    var onRequest: ((RPCRequest) async throws -> Void)?

    init(client: NotifyClient, logger: ConsoleLogging) {
        self.client = client
        self.logger = logger

        setupSubscriptions()
    }

    func setupSubscriptions() {
        client.notifyMessagePublisher.sink { [unowned self] record in
            handle(event: .notifyMessage, params: record.message)
        }.store(in: &publishers)

        client.newSubscriptionPublisher.sink { [unowned self] subscription in
            handle(event: .notifySubscription, params: subscription)
        }.store(in: &publishers)

        client.deleteSubscriptionPublisher.sink { [unowned self] topic in
            handle(event: .notifyDelete, params: topic)
        }.store(in: &publishers)

        client.updateSubscriptionPublisher.sink { [unowned self] subscription in
            handle(event: .notifyUpdate, params: subscription)
        }.store(in: &publishers)
        client.subscriptionsPublisher.sink { [unowned self] subscriptions in
            handle(event: .notifySubscriptionsChanged, params: subscriptions)
        }.store(in: &publishers)
    }
}

private extension NotifyClientRequestSubscriber {

    struct RequestPayload: Codable {
        let id: RPCID
        let account: Account
        let metadata: AppMetadata
    }

    func handle(event: NotifyClientRequest, params: Codable) {
        Task {
            do {
                let request = RPCRequest(
                    method: event.method,
                    params: params
                )
                try await onRequest?(request)
            } catch {
                logger.error("Client Request error: \(error.localizedDescription)")
            }
        }
    }
}
