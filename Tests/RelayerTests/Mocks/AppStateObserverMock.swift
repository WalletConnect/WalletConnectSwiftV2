import Foundation
@testable import WalletConnectRelay

class AppStateObserverMock: AppStateObserving {
    var onWillEnterForeground: (() -> Void)?
    var onWillEnterBackground: (() -> Void)?
}
