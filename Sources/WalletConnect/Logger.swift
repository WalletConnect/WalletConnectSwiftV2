// 

import Foundation

class Logger {
    private init() {}
    static func debug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        items.forEach {
            Swift.print($0, separator: separator, terminator: terminator)
        }
        #endif
    }
    
    static func error(_ items: Any..., separator: String = " ", terminator: String = "\n", file: String = #file, function: String = #function, line: Int = #line ) {
        #if DEBUG
        items.forEach {
            Swift.print("Error in File: \(file), Function: \(function), Line: \(line) - \($0)", separator: separator, terminator: terminator)
        }
        #endif
    }
}
