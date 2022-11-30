import Foundation

public struct AuthRequest: Equatable, Codable {
    public let id: RPCID
    public let params: AuthRequestParams
}
