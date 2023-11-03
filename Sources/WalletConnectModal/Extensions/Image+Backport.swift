import SwiftUI

extension Image {
    
    init(sfSymbolName: String) {
        if #available(macOS 11, iOS 13, *) {
            self.init(systemName: sfSymbolName)
        } else {
            self.init("", bundle: nil)
        }
    }
}
