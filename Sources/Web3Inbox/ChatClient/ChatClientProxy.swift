import Foundation

final class ChatClientProxy {

    private let client: ChatClient

    var onResponse: ((RPCResponse) async throws -> Void)?

    init(client: ChatClient) {
        self.client = client
    }

    func request(_ request: RPCRequest) async throws {
        guard let event = WebViewEvent(rawValue: request.method)
        else { throw Errors.unregisteredMethod }

        switch event {
        case .getInvites:
            let params = try parse(GetInvitesRequest.self, params: request.params)
            let invites = client.getInvites(account: params.account)
            try await respond(with: invites, request: request)

        case .getThreads:
            let params = try parse(GetThreadsRequest.self, params: request.params)
            let threads = client.getThreads(account: params.account)
            try await respond(with: threads, request: request)

        case .register:
            let params = try parse(RegisterRequest.self, params: request.params)
            try await client.register(account: params.account)

        case .getMessages:
            let params = try parse(GetMessagesRequest.self, params: request.params)
            let messages = client.getMessages(topic: params.topic)
            try await respond(with: messages, request: request)

        case .message:
            let params = try parse(MessageRequest.self, params: request.params)
            try await client.message(topic: params.topic, message: params.payload.message)
            try await respond(with: params.payload, request: request)

        case .accept:
            let params = try parse(AcceptRequest.self, params: request.params)
            try await client.accept(inviteId: params.id)
        }
    }
}

private extension ChatClientProxy {
    enum Errors: Error {
        case unregisteredMethod
        case unregisteredParams
    }

    struct GetInvitesRequest: Codable {
        let account: Account
    }

    struct GetThreadsRequest: Codable {
        let account: Account
    }

    struct RegisterRequest: Codable {
        let account: Account
    }

    struct GetMessagesRequest: Codable {
        let topic: String
    }

    struct MessageRequest: Codable {
        let topic: String
        let payload: Message
    }

    struct AcceptRequest: Codable {
        let id: Int64
    }

    func parse<Request: Codable>(_ type: Request.Type, params: AnyCodable?) throws -> Request {
        guard let params = try? params?.get([Request].self).first
        else { throw Errors.unregisteredParams }
        return params
    }

    func respond<Object: Codable>(with object: Object, request: RPCRequest) async throws {
        let response = RPCResponse(matchingRequest: request, result: object)
        try await onResponse?(response)
    }
}
