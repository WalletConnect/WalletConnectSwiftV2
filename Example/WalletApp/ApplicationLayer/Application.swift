import Foundation
import WalletConnectChat

final class Application {
    var uri: String?
    var requestSent = false
    let pushRegisterer = PushRegisterer()
}
