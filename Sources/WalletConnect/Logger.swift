// 

import Foundation


public class ConsoleLogger {
    private var loggingLevel: LoggingLevel
    private var suffix: String
    
    public func setLogging(level: LoggingLevel) {
        self.loggingLevel = level
    }

    init(suffix: String? = nil, loggingLevel: LoggingLevel = .warn) {
        self.suffix = suffix ?? ""
        self.loggingLevel = loggingLevel
    }
    
    func debug(_ items: Any...) {
        if loggingLevel >= .debug {
            items.forEach {
                Swift.print("\(suffix) \($0)")
            }
        }
    }
    
    func info(_ items: Any...) {
        if loggingLevel >= .info {
            items.forEach {
                Swift.print("\(suffix) \($0)")
            }
        }
    }
    
    func warn(_ items: Any...) {
        if loggingLevel >= .warn {
            items.forEach {
                Swift.print("\(suffix) ⚠️ \($0)")
            }
        }
    }
    
    func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line ) {
        if loggingLevel >= .error {
            items.forEach {
                Swift.print("\(suffix) Error in File: \(file), Function: \(function), Line: \(line) - \($0)")
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
