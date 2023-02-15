import Foundation

public protocol EchoClientProtocol {
    func register(deviceToken: Data) async throws
}
