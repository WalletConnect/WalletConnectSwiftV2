
import Foundation
@testable import Relayer

class BackgroundTaskRegistrarMock: BackgroundTaskRegistering {
    var completion: (()->())?
    func register(name: String, completion: @escaping () -> ()) {
        self.completion = completion
    }
}
