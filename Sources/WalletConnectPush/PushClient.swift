import Foundation

public class PushClient: PushClientProtocol {
    private let registerService: PushRegisterService

    init(registerService: PushRegisterService) {
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
