import Foundation
import Mixpanel
import WalletConnectNetworking
import Combine
import Web3Inbox

final class ProfilingService {
    public static var instance = ProfilingService()

    private let queue = DispatchQueue(label: "com.walletApp.profilingService")
    private var publishers = [AnyCancellable]()
    private var isProfiling = false

    func setUpProfiling(account: String, clientId: String) {
        queue.sync {
            guard isProfiling == false else { return }
            isProfiling = true
        }
        guard let token = InputConfig.mixpanelToken, !token.isEmpty  else { return }

        Mixpanel.initialize(token: token, trackAutomaticEvents: true)
        Mixpanel.mainInstance().alias = "Bartek"
        Mixpanel.mainInstance().identify(distinctId: clientId)
        Mixpanel.mainInstance().people.set(properties: [ "account": account])


        Networking.instance.logsPublisher
            .sink { [unowned self] log in
                self.queue.sync {
                    switch log {
                    case .error(let logMessage):
                        send(logMessage: logMessage)
                    case .warn(let logMessage):
                        send(logMessage: logMessage)
                    case .debug(let logMessage):
                        send(logMessage: logMessage)
                    default:
                        return
                    }
                }
            }
            .store(in: &publishers)
        
        Web3Inbox.instance.logsPublisher
            .sink { [unowned self] log in
                self.queue.sync {
                    switch log {
                    case .error(let logMessage):
                        send(logMessage: logMessage)
                    case .warn(let logMessage):
                        send(logMessage: logMessage)
                    case .debug(let logMessage):
                        send(logMessage: logMessage)
                    default:
                        return
                    }
                }
            }
        .store(in: &publishers)
    }

    func send(logMessage: LogMessage) {
        Mixpanel.mainInstance().track(event: logMessage.message, properties: logMessage.properties)
    }
}
