import Foundation

public extension Int {
    static func random() -> Int {
        random(in: Int.min...Int.max)
    }
}

public extension Double {
    static func random() -> Double {
        random(in: 0...1)
    }
}

public extension Result {
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

public extension NSError {
    
    static func mock(code: Int = -9999) -> NSError {
        NSError(domain: "com.walletconnect.sdk.tests.error", code: code, userInfo: nil)
    }
}
