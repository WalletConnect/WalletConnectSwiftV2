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
    
    static func error(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        items.forEach {
            Swift.print($0, separator: separator, terminator: terminator)
        }
        #endif
    }
}
