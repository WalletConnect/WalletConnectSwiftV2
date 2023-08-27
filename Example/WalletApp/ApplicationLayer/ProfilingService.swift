import Foundation
import Mixpanel

final class ProfilingService {
    public static var instance = ProfilingService()

    func setUpProfiling(account: String, clientId: String) {
        Mixpanel.initialize(token: "", trackAutomaticEvents: true)
        Mixpanel.mainInstance().identify(distinctId: clientId)
        Mixpanel.mainInstance().people.set(properties: [ "account": account])
    }
}