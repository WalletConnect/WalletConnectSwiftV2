import Foundation
import Mixpanel

final class ProfilingService {
    public static var instance = ProfilingService()

    func setUpProfiling(account: String, clientId: String) {
        Mixpanel.mainInstance().identify(distinctId: clientId)
        Mixpanel.mainInstance().people.set(properties: [ "account": account])
    }
}
