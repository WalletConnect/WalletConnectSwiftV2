import Foundation

public struct SignAuthRequest: Equatable, Codable {
    public let id: RPCID
    public let topic: String
    public let payload: SignAuthPayload
}
