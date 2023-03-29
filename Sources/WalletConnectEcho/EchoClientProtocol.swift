import Foundation

public protocol EchoClientProtocol {
    func register(deviceToken: Data) async throws
#if DEBUG
    func register(deviceToken: String) async throws
#endif
}
