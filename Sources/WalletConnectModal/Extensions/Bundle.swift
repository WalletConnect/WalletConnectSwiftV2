import Foundation

#if CocoaPods
extension Bundle {
    static var module: Bundle { Bundle.init(for: WalletConnectModal.self) }
}
#endif
