import Foundation
import Combine

final class PushClientRequestSubscriber {

    private var publishers: Set<AnyCancellable> = []

    private let client: WalletPushClient
    private let logger: ConsoleLogging

    var onRequest: ((RPCRequest) async throws -> Void)?

    init(client: WalletPushClient, logger: ConsoleLogging) {
        self.client = client
        self.logger = logger

        setupSubscriptions()
    }

    func setupSubscriptions() {
        client.requestPublisher.sink { [unowned self] id, account, metadata in
            let params = RequestPayload(id: id, account: account, metadata: metadata)
            handle(event: .pushRequest, params: params)
        }.store(in: &publishers)

        client.pushMessagePublisher.sink { [unowned self] record in
            handle(event: .pushMessage, params: record)
        }.store(in: &publishers)

        client.deleteSubscriptionPublisher.sink { [unowned self] record in
            handle(event: .pushDelete, params: record)
        }.store(in: &publishers)

        client.subscriptionPublisher.sink { [unowned self] record in
            switch record {
            case .success(let subscription):
                handle(event: .pushSubscription, params: subscription)
            case .failure:
                //TODO - handle error
                break

            }
        }.store(in: &publishers)

        client.updateSubscriptionPublisher.sink { [unowned self] record in
            switch record {
            case .success(let subscription):
                handle(event: .pushUpdate, params: subscription)
            case .failure:
                //TODO - handle error
                break
            }
        }.store(in: &publishers)
    }
}

private extension PushClientRequestSubscriber {

    struct RequestPayload: Codable {
        let id: RPCID
        let account: Account
        let metadata: AppMetadata
    }

    func handle(event: PushClientRequest, params: Codable) {
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
