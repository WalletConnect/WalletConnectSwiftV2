// 

import Foundation

class BaseLogger {
    func debug(_ items: Any...) {
        fatalError("Logging Subclass shoud implement the method")
    }
    
    func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line ) {
        fatalError("Logging Subclass shoud implement the method")
    }
}

class ConsoleLogger: BaseLogger {
    override func debug(_ items: Any...) {
        #if DEBUG
        items.forEach {
            Swift.print($0)
        }
        #endif
    }
    
    override func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line ) {
        #if DEBUG
        items.forEach {
            Swift.print("Error in File: \(file), Function: \(function), Line: \(line) - \($0)")
        }
        #endif
    }
}

class MuteLogger: BaseLogger {
    override func debug(_ items: Any...) {}
    override func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line ) {}
}
