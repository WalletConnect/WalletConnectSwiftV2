import Foundation

public struct AuthRequest: Equatable, Codable {
    public let id: RPCID
    public let topic: String
    public let payload: AuthPayloadStruct
    public let requester: AppMetadata
}
