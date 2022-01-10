// 

import Foundation
import Relayer

/// Logging Protocol
public protocol ConsoleLogging: Relayer.ConsoleLogging {
    /// Writes a debug message to the log.
    func debug(_ items: Any...)
    
    /// Writes an informative message to the log.
    func info(_ items: Any...)
    
    /// Writes information about a warning to the log.
    func warn(_ items: Any...)
    
    /// Writes information about an error to the log.
    func error(_ items: Any...)
}
