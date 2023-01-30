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
            let invites = client.getInvites()
            try await respond(with: invites, request: request)

        case .getThreads:
            let threads = client.getThreads()
            try await respond(with: threads, request: request)

        case .register:
            let params = try parse(RegisterRequest.self, params: request.params)
            try await client.register(account: params.account)
            try await respond(request: request)

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
            try await respond(request: request)

        case .reject:
            let params = try parse(RejectRequest.self, params: request.params)
            try await client.reject(inviteId: params.id)
            try await respond(request: request)

        case .invite:
            let params = try parse(InviteRequest.self, params: request.params)
            try await client.invite(peerAccount: params.invite.account, openingMessage: params.invite.message)
            try await respond(request: request)
        }
    }
}

private extension ChatClientProxy {

    private typealias Blob = Dictionary<String, String>

    enum Errors: Error {
        case unregisteredMethod
        case unregisteredParams
    }

    struct RegisterRequest: Codable {
        let account: Account
    }

    struct GetMessagesRequest: Codable {
        let topic: String
    }

    struct MessageRequest: Codable {
        let topic: String
        let payload: MessagePayload
    }

    struct AcceptRequest: Codable {
        let id: Int64
    }

    struct RejectRequest: Codable {
        let id: Int64
    }

    struct InviteRequest: Codable {
        struct Invite: Codable {
            let account: Account
            let message: String
        }
        let account: Account
        let invite: Invite
    }

    func parse<Request: Codable>(_ type: Request.Type, params: AnyCodable?) throws -> Request {
        guard let params = try params?.get([Request].self).first
        else { throw Errors.unregisteredParams }
        return params
    }

    func respond<Object: Codable>(with object: Object = Blob(), request: RPCRequest) async throws {
        let response = RPCResponse(matchingRequest: request, result: object)
        try await onResponse?(response)
    }
}
