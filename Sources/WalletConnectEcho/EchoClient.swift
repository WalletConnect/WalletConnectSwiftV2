import Foundation

public class EchoClient: EchoClientProtocol {
    private let registerService: EchoRegisterService

    init(registerService: EchoRegisterService) {
        self.registerService = registerService
    }

    public func register(deviceToken: Data) async throws {
        try await registerService.register(deviceToken: deviceToken)
    }

#if DEBUG
    public func register(deviceToken: String) async throws {
        try await registerService.register(deviceToken: deviceToken)
    }
#endif
}
