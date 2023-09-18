import Foundation

final class NotifyClientProxy {

    private let client: NotifyClient

    var onSign: SigningCallback
    var onResponse: ((RPCResponse, RPCRequest) async throws -> Void)?

    init(client: NotifyClient, onSign: @escaping SigningCallback) {
        self.client = client
        self.onSign = onSign
    }

    func request(_ request: RPCRequest) async throws {
        guard let event = NotifyWebViewEvent(rawValue: request.method)
        else { throw Errors.unregisteredMethod }

        // TODO: Handle register event

        switch event {
        case .update:
            let params = try parse(UpdateRequest.self, params: request.params)
            try await client.update(topic: params.topic, scope: params.scope)
            try await respond(request: request)
        case .subscribe:
            let params = try parse(SubscribeRequest.self, params: request.params)
            try await client.subscribe(appDomain: appDomain, account: params.account)
            try await respond(request: request)
        case .getActiveSubscriptions: 
            let subscriptions = client.getActiveSubscriptions()
            try await respond(with: subscriptions, request: request)
        case .getMessageHistory:
            let params = try parse(GetMessageHistoryRequest.self, params: request.params)
            let messages = client.getMessageHistory(topic: params.topic)
            try await respond(with: messages, request: request)
        case .deleteSubscription:
            let params = try parse(DeleteSubscriptionRequest.self, params: request.params)
            try await client.deleteSubscription(topic: params.topic)
            try await respond(request: request)
        case .deleteNotifyMessage:
            let params = try parse(DeleteNotifyMessageRequest.self, params: request.params)
            client.deleteNotifyMessage(id: params.id.string)
            try await respond(request: request)
        case .register:
            let params = try parse(RegisterRequest.self, params: request.params)
            try await client.register(account: params.account, domain: params.domain, isLimited: params.isLimited, onSign: onSign)
            try await respond(request: request)
        }
    }
}

private extension NotifyClientProxy {

    private typealias Blob = Dictionary<String, String>

    enum Errors: Error {
        case unregisteredMethod
        case unregisteredParams
    }

    struct ApproveRequest: Codable {
        let id: RPCID
    }

    struct UpdateRequest: Codable {
        let topic: String
        let scope: Set<String>
    }

    struct RejectRequest: Codable {
        let id: RPCID
    }

    struct SubscribeRequest: Codable {
        let appDomain: String
        let account: Account
    }

    struct GetMessageHistoryRequest: Codable {
        let topic: String
    }

    struct DeleteSubscriptionRequest: Codable {
        let topic: String
    }

    struct DeleteNotifyMessageRequest: Codable {
        let id: RPCID
    }

    struct RegisterRequest: Codable {
        let account: Account
        let domain: String
        let isLimited: Bool
    }

    func parse<Request: Codable>(_ type: Request.Type, params: AnyCodable?) throws -> Request {
        guard let params = try params?.get(Request.self)
        else { throw Errors.unregisteredParams }
        return params
    }

    func respond<Object: Codable>(with object: Object = Blob(), request: RPCRequest) async throws {
        let response = RPCResponse(matchingRequest: request, result: object)
        try await onResponse?(response, request)
    }
}
