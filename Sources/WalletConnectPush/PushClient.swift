import Foundation
import Combine

public class PushClient: PushClientProtocol {
    private let registerService: PushRegisterService
    private let unregisterService: UnregisterService
    private let logger: ConsoleLogging

    public var logsPublisher: AnyPublisher<Log, Never> {
        return logger.logsPublisher
    }

    init(registerService: PushRegisterService,
         logger: ConsoleLogging,
         unregisterService: UnregisterService) {
        self.registerService = registerService
        self.unregisterService = unregisterService
        self.logger = logger
    }

    public func register(deviceToken: Data, enableEncrypted: Bool = false) async throws {
        try await registerService.register(deviceToken: deviceToken, alwaysRaw: enableEncrypted)
    }

    public func unregister() async throws {
        try await unregisterService.unregister()
    }

#if DEBUG
    public func register(deviceToken: String) async throws {
        try await registerService.register(deviceToken: deviceToken, alwaysRaw: true)
    }
#endif
}


#if DEBUG
final class PushClientMock: PushClientProtocol {
    var registedCalled = false

    func register(deviceToken: Data) async throws {
        registedCalled = true
    }

    func register(deviceToken: String) async throws {
        registedCalled = true
    }
}
#endif
