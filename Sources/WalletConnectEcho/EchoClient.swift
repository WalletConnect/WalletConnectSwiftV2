import Foundation

public class EchoClient: EchoClientProtocol {
    private let registerService: EchoRegisterService

    /// The property is used to determine whether echo.walletconnect.org will be used
    /// in case echo.walletconnect.com doesn't respond for some reason (most likely due to being blocked in the user's location).
    private var fallback = false
    
    init(registerService: EchoRegisterService) {
        self.registerService = registerService
    }

    public func register(deviceToken: Data) async throws {
        do {
            try await registerService.register(deviceToken: deviceToken)
        } catch {
            if (error as? HTTPError) == .couldNotConnect && !fallback {
                fallback = true
                await registerService.echoHostFallback()
                try await registerService.register(deviceToken: deviceToken)
            }
            throw error
        }
    }

#if DEBUG
    public func register(deviceToken: String) async throws {
        do {
            try await registerService.register(deviceToken: deviceToken)
        } catch {
            if (error as? HTTPError) == .couldNotConnect && !fallback {
                fallback = true
                await registerService.echoHostFallback()
                try await registerService.register(deviceToken: deviceToken)
            }
            throw error
        }
    }
#endif
}


#if DEBUG
final class EchoClientMock: EchoClientProtocol {
    var registedCalled = false

    func register(deviceToken: Data) async throws {
        registedCalled = true
    }

    func register(deviceToken: String) async throws {
        registedCalled = true
    }
}
#endif
