import Foundation
import UIKit

struct UIPasteboardWrapper {
    static var string: String? {
        UIPasteboard.general.string
    }
}
