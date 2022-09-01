import Foundation
@testable import WalletConnectRelay

class BackgroundTaskRegistrarMock: BackgroundTaskRegistering {
    var completion: (() -> Void)?

    func register(name: String, completion: @escaping () -> Void) {
        self.completion = completion
    }

    func invalidate() {

    }
}
