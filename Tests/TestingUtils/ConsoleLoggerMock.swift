
import Foundation
import WalletConnectUtils
@testable import WalletConnect

public struct ConsoleLoggerMock: ConsoleLogging {
    public init() {}
    public func error(_ items: Any...) {
    }
    
    public func debug(_ items: Any...) {
    }
    
    public func info(_ items: Any...) {
    }
    
    public func warn(_ items: Any...) {
    }
}
