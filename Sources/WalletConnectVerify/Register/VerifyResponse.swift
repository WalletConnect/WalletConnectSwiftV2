import Foundation

public struct VerifyResponse: Decodable {
    public let origin: String?
    public let isScam: Bool?
    public let isVerified: Bool?
}
