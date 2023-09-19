import Foundation
import Combine

public protocol ConsoleLogging: ErrorHandler {
    var logsPublisher: AnyPublisher<Log, Never> { get }
    func debug(_ items: Any..., file: String, function: String, line: Int, properties: [String: String]?)
    func info(_ items: Any..., file: String, function: String, line: Int)
    func warn(_ items: Any..., file: String, function: String, line: Int)
    func error(_ items: Any..., file: String, function: String, line: Int)
    func setLogging(level: LoggingLevel)
}

public extension ConsoleLogging {
    func debug(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line, properties: [String: String]? = nil) {
        debug(items, file: file, function: function, line: line, properties: properties)
    }
    func info(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        info(items, file: file, function: function, line: line)
    }
    func warn(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        warn(items, file: file, function: function, line: line)
    }
    func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        error(items, file: file, function: function, line: line)
    }
}

public class ConsoleLogger {
    private var loggingLevel: LoggingLevel
    private var prefix: String
    private var logsPublisherSubject = PassthroughSubject<Log, Never>()
    public var logsPublisher: AnyPublisher<Log, Never> {
        return logsPublisherSubject.eraseToAnyPublisher()
    }

    public func setLogging(level: LoggingLevel) {
        self.loggingLevel = level
    }

    public init(prefix: String? = nil, loggingLevel: LoggingLevel = .warn) {
        self.prefix = prefix ?? ""
        self.loggingLevel = loggingLevel
    }

    private func logMessage(_ items: Any..., logType: LoggingLevel, file: String = #file, function: String = #function, line: Int = #line, properties: [String: String]? = nil) {
        let fileName = (file as NSString).lastPathComponent
        items.forEach {
            var logMessage = "\($0)"
            var properties = properties ?? [String: String]()
            properties["fileName"] = fileName
            properties["line"] = "\(line)"
            properties["function"] = function
            switch logType {
            case .debug:
                logMessage = "\(prefix) \(logMessage)"
                logsPublisherSubject.send(.debug(LogMessage(message: logMessage, properties: properties)))
            case .info:
                logMessage = "\(prefix) ℹ️ \(logMessage)"
                logsPublisherSubject.send(.info(LogMessage(message: logMessage, properties: properties)))
            case .warn:
                logMessage = "\(prefix) ⚠️ \(logMessage)"
                logsPublisherSubject.send(.warn(LogMessage(message: logMessage, properties: properties)))
            case .error:
                logMessage = "\(prefix) ‼️ \(logMessage)"
                logsPublisherSubject.send(.error(LogMessage(message: logMessage, properties: properties)))
            case .off:
                return
            }
            logMessage = "\(prefix) [\(fileName)]: \($0) - \(function) - line: \(line) - \(logFormattedDate(Date()))"
            Swift.print(logMessage)
        }
    }

    private func logFormattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}


extension ConsoleLogger: ConsoleLogging {
    public func debug(_ items: Any..., file: String, function: String, line: Int, properties: [String : String]?) {
        if loggingLevel >= .debug {
            logMessage(items, logType: .debug, file: file, function: function, line: line, properties: properties)
        }
    }

    public func info(_ items: Any..., file: String, function: String, line: Int) {
        if loggingLevel >= .info {
            logMessage(items, logType: .info, file: file, function: function, line: line)
        }
    }

    public func warn(_ items: Any..., file: String, function: String, line: Int) {
        if loggingLevel >= .warn {
            logMessage(items, logType: .warn, file: file, function: function, line: line)
        }
    }

    public func error(_ items: Any..., file: String, function: String, line: Int) {
        if loggingLevel >= .error {
            logMessage(items, logType: .error, file: file, function: function, line: line)
        }
    }

    public func handle(error: Error) {
        self.error(error.localizedDescription)
    }
}

#if DEBUG
public struct ConsoleLoggerMock: ConsoleLogging {
    public var logsPublisher: AnyPublisher<Log, Never> {
        return PassthroughSubject<Log, Never>().eraseToAnyPublisher()
    }

    public init() {}

    public func debug(_ items: Any..., file: String, function: String, line: Int, properties: [String: String]?) { }
    public func info(_ items: Any..., file: String, function: String, line: Int) { }
    public func warn(_ items: Any..., file: String, function: String, line: Int) { }
    public func error(_ items: Any..., file: String, function: String, line: Int) { }

    public func setLogging(level: LoggingLevel) { }

    public func handle(error: Error) { }
}
#endif

