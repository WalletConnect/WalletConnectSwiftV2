
import SwiftUI
import UIKit

enum Asset: String {
    
    // Icons
    case close
    case external_link
    case help
    case wallet
    
    // large
    case copy_large
    case qr_large
    
    // Images
    case walletconnect_logo
    case wc_logo
    
    // Help
    case Browser
    case DAO
    case DeFi
    case ETH
    case Layers
    case Lock
    case Login
    case Network
    case NFT
    case Noun
    case Profile
    case System
}

extension Asset {
    
    var image: Image {
        Image(self)
    }
    
    var uiImage: UIImage {
        UIImage(self)
    }
}

extension Image {
    
    init(_ asset: Asset) {
        self.init(asset.rawValue, bundle: .module)
    }
}

extension UIImage {
    
    convenience init(_ asset: Asset) {
        self.init(named: asset.rawValue, in: .module, compatibleWith: .current)!
    }
}
