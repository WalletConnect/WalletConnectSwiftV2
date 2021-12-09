
import Foundation
@testable import WalletConnect

struct ConsoleLoggerMock: ConsoleLogging {
    func error(_ items: Any..., file: String, function: String, line: Int) {
    }
    
    func debug(_ items: Any...) {
    }
    
    func info(_ items: Any...) {
    }
    
    func warn(_ items: Any...) {
    }
}
