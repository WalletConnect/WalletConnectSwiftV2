// 

import Foundation

class BaseLogger {
    private let suffix: String
    init(suffix: String = "") {
        self.suffix = suffix
    }
    func debug(_ items: Any...) {
        fatalError("Logging Subclass shoud implement the method")
    }
    
    func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line ) {
        fatalError("Logging Subclass shoud implement the method")
    }
}

class ConsoleLogger: BaseLogger {
    private let suffix: String
    
    override init(suffix: String = "") {
        self.suffix = suffix
    }
    
    override func debug(_ items: Any...) {
        #if DEBUG
        items.forEach {
            Swift.print("\(suffix) \($0)")
        }
        #endif
    }
    
    override func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line ) {
        #if DEBUG
        items.forEach {
            Swift.print("\(suffix) Error in File: \(file), Function: \(function), Line: \(line) - \($0)")
        }
        #endif
    }
}

class MuteLogger: BaseLogger {
    override func debug(_ items: Any...) {}
    override func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line ) {}
}
