import Foundation
import Combine

/// Logging Protocol
public protocol ConsoleLogging {
    var logsPublisher: AnyPublisher<Log, Never> { get }
    /// Writes a debug message to the log.
    func debug(_ items: Any...)

    /// Writes an informative message to the log.
    func info(_ items: Any...)

    /// Writes information about a warning to the log.
    func warn(_ items: Any...)

    /// Writes information about an error to the log.
    func error(_ items: Any...)

    func setLogging(level: LoggingLevel)
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

    public func debug(_ items: Any...) {
        if loggingLevel >= .debug {
            items.forEach {
                let log = "\(suffix) \($0) - \(logFormattedDate(Date()))"
                Swift.print(log)
                logsPublisherSubject.send(.debug(log))
            }
        }
    }

    public func info(_ items: Any...) {
        if loggingLevel >= .info {
            items.forEach {
                let log = "\(suffix) \($0) - \(logFormattedDate(Date()))"
                Swift.print(log)
                logsPublisherSubject.send(.info(log))            }
        }
    }

    public func warn(_ items: Any...) {
        if loggingLevel >= .warn {
            items.forEach {
                let log = "\(suffix) ⚠️ \($0) - \(logFormattedDate(Date()))"
                Swift.print(log)
                logsPublisherSubject.send(.warn(log))
            }
        }
    }

    public func error(_ items: Any...) {
        if loggingLevel >= .error {
            items.forEach {
                let log = "\(suffix) ‼️ \($0) - \(logFormattedDate(Date()))"
                Swift.print(log)
                logsPublisherSubject.send(.error(log))
            }
        }
    }
}


fileprivate func logFormattedDate(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = NSLocale.current
    dateFormatter.dateFormat = "HH:mm:ss.SSSS"
    return  dateFormatter.string(from: date)
}


#if DEBUG
public struct ConsoleLoggerMock: ConsoleLogging {
    public var logsPublisher: AnyPublisher<WalletConnectUtils.Log, Never> {
        return PassthroughSubject<WalletConnectUtils.Log, Never>().eraseToAnyPublisher()
    }
    public init() {}
    public func error(_ items: Any...) { }
    public func debug(_ items: Any...) { }
    public func info(_ items: Any...) { }
    public func warn(_ items: Any...) { }
    public func setLogging(level: LoggingLevel) { }
}
#endif
