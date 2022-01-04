
import Foundation

public protocol ConsoleLogging {
    func debug(_ items: Any...)
    func info(_ items: Any...)
    func warn(_ items: Any...)
    func error(_ items: Any...)
    func setLogging(level: LoggingLevel)
}

public class ConsoleLogger: ConsoleLogging {
    private var loggingLevel: LoggingLevel
    private var suffix: String
    
    public func setLogging(level: LoggingLevel) {
        self.loggingLevel = level
    }

    public init(suffix: String? = nil, loggingLevel: LoggingLevel = .warn) {
        self.suffix = suffix ?? ""
        self.loggingLevel = loggingLevel
    }
    
    public func debug(_ items: Any...) {
        if loggingLevel >= .debug {
            items.forEach {
                Swift.print("\(suffix) \($0)")
            }
        }
    }
    
    public func info(_ items: Any...) {
        if loggingLevel >= .info {
            items.forEach {
                Swift.print("\(suffix) \($0)")
            }
        }
    }
    
    public func warn(_ items: Any...) {
        if loggingLevel >= .warn {
            items.forEach {
                Swift.print("\(suffix) ⚠️ \($0)")
            }
        }
    }
    
    public func error(_ items: Any...) {
        if loggingLevel >= .error {
            items.forEach {
                Swift.print("\(suffix) ‼️ \($0)")
            }
        }
    }
}

public enum LoggingLevel: Comparable {
    case off
    case error
    case warn
    case info
    case debug
}
