import Foundation
import Mixpanel

final class ProfilingService {
    public static var instance = ProfilingService()

    func setUpProfiling(account: String, clientId: String) {
        guard let token = InputConfig.mixpanelToken, !token.isEmpty  else { return }
        Mixpanel.initialize(token: token, trackAutomaticEvents: true)
        Mixpanel.mainInstance().identify(distinctId: clientId)
        Mixpanel.mainInstance().people.set(properties: [ "account": account])
    }
}
