
import Foundation
@testable import WalletConnectRelay

class AppStateObserverMock: AppStateObserving {
    var onWillEnterForeground: (() -> ())?
    var onWillEnterBackground: (() -> ())?
}
