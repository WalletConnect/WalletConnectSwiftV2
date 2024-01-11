#if os(iOS)
import UIKit
public struct WalletConnectRouter {
    public static func goBack(uri: String) {
        if #available(iOS 17, *) {
            DispatchQueue.main.async {
                if let url = URL(string: uri) {
                    UIApplication.shared.open(url)
                }
            }
        } else {
            Router.goBack()
        }
    }
}
#endif
