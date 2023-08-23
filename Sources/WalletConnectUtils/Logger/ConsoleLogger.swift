import Foundation
import Combine

/// Logging Protocol

import Combine

public protocol ConsoleLogging {
    var logsPublisher: AnyPublisher<Log, Never> { get }

    func debug(_ items: Any...)
    func info(_ items: Any...)
    func warn(_ items: Any...)
    func error(_ items: Any...)

    func _debug(_ items: Any..., file: String, function: String, line: Int)
    func _info(_ items: Any..., file: String, function: String, line: Int)
    func _warn(_ items: Any..., file: String, function: String, line: Int)
    func _error(_ items: Any..., file: String, function: String, line: Int)

    func setLogging(level: LoggingLevel)
}

public extension ConsoleLogging {
    func debug(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _debug(items, file: file, function: function, line: line)
    }
    func info(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _info(items, file: file, function: function, line: line)
    }
    func warn(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _warn(items, file: file, function: function, line: line)
    }
    func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _error(items, file: file, function: function, line: line)
    }
}

public class ConsoleLogger: ConsoleLogging {
    private var loggingLevel: LoggingLevel
    private var suffix: String
    private var logsPublisherSubject = PassthroughSubject<Log, Never>()
    public var logsPublisher: AnyPublisher<Log, Never> {
        return logsPublisherSubject.eraseToAnyPublisher()
    }

    public func setLogging(level: LoggingLevel) {
        self.loggingLevel = level
    }

    public init(suffix: String? = nil, loggingLevel: LoggingLevel = .warn) {
        self.suffix = suffix ?? ""
        self.loggingLevel = loggingLevel
    }

    private func logMessage(_ items: Any..., logType: LoggingLevel, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        items.forEach {
            var log = "\(suffix) [\(fileName) - \(function) - line: \(line)] \($0) - \(logFormattedDate(Date()))"

            switch logType {
            case .debug:
                logsPublisherSubject.send(.debug(log))
            case .info:
                logsPublisherSubject.send(.info(log))
            case .warn:
                log = "\(suffix) ⚠️ \(log)"
                logsPublisherSubject.send(.warn(log))
            case .error:
                log = "\(suffix) ‼️ \(log)"
                logsPublisherSubject.send(.error(log))
            case .off:
                return
            }

            Swift.print(log)
        }
    }

    public func debug(_ items: Any...) {
        fatalError()
    }
    public func info(_ items: Any...) {
        fatalError()
    }
    public func warn(_ items: Any...) {
        fatalError()
    }
    public func error(_ items: Any...) {
        fatalError()
    }

    public func _debug(_ items: Any..., file: String, function: String, line: Int) {
        if loggingLevel >= .debug {
            logMessage(items, logType: .debug, file: file, function: function, line: line)
        }
    }

    public func _info(_ items: Any..., file: String, function: String, line: Int) {
        if loggingLevel >= .info {
            logMessage(items, logType: .info, file: file, function: function, line: line)
        }
    }

    public func _warn(_ items: Any..., file: String, function: String, line: Int) {
        if loggingLevel >= .warn {
            logMessage(items, logType: .warn, file: file, function: function, line: line)
        }
    }

    public func _error(_ items: Any..., file: String, function: String, line: Int) {
        if loggingLevel >= .error {
            logMessage(items, logType: .error, file: file, function: function, line: line)
        }
    }

    private func logFormattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}


public extension ConsoleLogger {
    func debug(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _debug(items, file: file, function: function, line: line)
    }

    func info(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _info(items, file: file, function: function, line: line)
    }

    func warn(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _warn(items, file: file, function: function, line: line)
    }

    func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _error(items, file: file, function: function, line: line)
    }
}


#if DEBUG
public struct ConsoleLoggerMock: ConsoleLogging {
    public var logsPublisher: AnyPublisher<WalletConnectUtils.Log, Never> {
        return PassthroughSubject<WalletConnectUtils.Log, Never>().eraseToAnyPublisher()
    }

    public init() {}
    public func debug(_ items: Any...) {
        fatalError()
    }
    public func info(_ items: Any...) {
        fatalError()
    }
    public func warn(_ items: Any...) {
        fatalError()
    }
    public func error(_ items: Any...) {
        fatalError()
    }

    public func _debug(_ items: Any..., file: String, function: String, line: Int) { }
    public func _info(_ items: Any..., file: String, function: String, line: Int) { }
    public func _warn(_ items: Any..., file: String, function: String, line: Int) { }
    public func _error(_ items: Any..., file: String, function: String, line: Int) { }

    public func setLogging(level: LoggingLevel) { }
}
#endif


#if DEBUG
extension ConsoleLoggerMock {
    func debug(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _debug(items, file: file, function: function, line: line)
    }

    func info(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _info(items, file: file, function: function, line: line)
    }

    func warn(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _warn(items, file: file, function: function, line: line)
    }

    func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        _error(items, file: file, function: function, line: line)
    }
}
#endif
