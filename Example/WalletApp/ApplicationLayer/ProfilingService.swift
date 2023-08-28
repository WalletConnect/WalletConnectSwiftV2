import Foundation
import Mixpanel
import WalletConnectNetworking
import Combine

final class ProfilingService {
    public static var instance = ProfilingService()

    private let queue = DispatchQueue(label: "com.walletApp.loggingService")
    private var publishers = [AnyCancellable]()
    private var isProfiling = false

    func setUpProfiling(account: String, clientId: String) {
        queue.sync {
            guard isProfiling == false else { return }
            isProfiling = true
        }
        guard let token = InputConfig.mixpanelToken, !token.isEmpty  else { return }
        Mixpanel.initialize(token: token, trackAutomaticEvents: true)
        Mixpanel.mainInstance().identify(distinctId: clientId)
        Mixpanel.mainInstance().people.set(properties: [ "account": account])


        Networking.instance.logsPublisher
            .sink { [unowned self] log in
                self.queue.sync {
                    switch log {
                    case .error(let log):
                        send(event: log)
                    case .warn(let log):
                        send(event: log)
                    case .debug(let log):
                        send(event: log)
                    default:
                        return
                    }
                }
            }
            .store(in: &publishers)
    }

    func send(event: String) {
        Mixpanel.mainInstance().track(event: event)
    }


}
