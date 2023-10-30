import UIKit

public struct WalletConnectRouter {
    public static func goBack(uri: String) {
        DispatchQueue.main.async {
            UIApplication.shared.open(URL(string: uri)!)
        }
    }
}
