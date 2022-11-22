import Foundation
@testable import WalletConnectRelay

class AppStateObserverMock: AppStateObserving {
    var currentState: ApplicationState = .foreground
    var onWillEnterForeground: (() -> Void)?
    var onWillEnterBackground: (() -> Void)?
}
