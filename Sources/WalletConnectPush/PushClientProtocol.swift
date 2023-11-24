import Foundation

public protocol PushClientProtocol {
    func register(deviceToken: Data, enableEncrypted: Bool) async throws
#if DEBUG
    func register(deviceToken: String) async throws
#endif
}

public extension PushClientProtocol {
    func register(deviceToken: Data, enableEncrypted: Bool = false) async throws {
        try await register(deviceToken: deviceToken, enableEncrypted: enableEncrypted)
    }
}
