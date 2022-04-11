// 

import Foundation

// TODO: Migrate, over time, the usage of these values to TimeInverval extension in Commons.
enum Time {
    
    static let hour = 3600
    
    static var day: Int {
        hour * 24
    }
    
    static var minute: Int {
        60
    }
}
