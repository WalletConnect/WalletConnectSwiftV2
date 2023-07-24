import Foundation

public protocol PushClientProtocol {
    func register(deviceToken: Data) async throws
#if DEBUG
    func register(deviceToken: String) async throws
#endif
}
