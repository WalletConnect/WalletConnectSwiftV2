import Foundation

final class PushClientProxy {

    private let client: WalletPushClient

    var onSign: SigningCallback
    var onResponse: ((RPCResponse) async throws -> Void)?

    init(client: WalletPushClient, onSign: @escaping SigningCallback) {
        self.client = client
        self.onSign = onSign
    }

    func request(_ request: RPCRequest) async throws {
        guard let event = PushWebViewEvent(rawValue: request.method)
        else { throw Errors.unregisteredMethod }

        switch event {
        case .approve:
            let params = try parse(ApproveRequest.self, params: request.params)
            try await client.approve(id: params.id, onSign: onSign)
            try await respond(request: request)
        case .update:
            let params = try parse(UpdateRequest.self, params: request.params)
            try await client.update(topic: params.topic, scope: params.scope)
            try await respond(request: request)
        case .reject:
            let params = try parse(RejectRequest.self, params: request.params)
            try await client.reject(id: params.id)
            try await respond(request: request)
        case .subscribe:
            let params = try parse(SubscribeRequest.self, params: request.params)
            try await client.subscribe(metadata: params.metadata, account: params.account, onSign: onSign)
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
        case .deletePushMessage:
            let params = try parse(DeletePushMessageRequest.self, params: request.params)
            client.deletePushMessage(id: params.id)
            try await respond(request: request)
        }
    }
}

private extension PushClientProxy {

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
        let metadata: AppMetadata
        let account: Account
    }

    struct GetMessageHistoryRequest: Codable {
        let topic: String
    }

    struct DeleteSubscriptionRequest: Codable {
        let topic: String
    }

    struct DeletePushMessageRequest: Codable {
        let id: String
    }

    func parse<Request: Codable>(_ type: Request.Type, params: AnyCodable?) throws -> Request {
        guard let params = try params?.get(Request.self)
        else { throw Errors.unregisteredParams }
        return params
    }

    func respond<Object: Codable>(with object: Object = Blob(), request: RPCRequest) async throws {
        let response = RPCResponse(matchingRequest: request, result: object)
        try await onResponse?(response)
    }
}
