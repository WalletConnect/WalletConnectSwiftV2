
import Foundation
@testable import WalletConnectRelay

class BackgroundTaskRegistrarMock: BackgroundTaskRegistering {
    var completion: (()->())?
    func register(name: String, completion: @escaping () -> ()) {
        self.completion = completion
    }
}
