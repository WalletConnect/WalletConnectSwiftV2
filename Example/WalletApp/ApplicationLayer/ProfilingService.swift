import Foundation
import Mixpanel
import WalletConnectNetworking
import Combine
import Web3Wallet
import WalletConnectNotify

final class ProfilingService {
    public static var instance = ProfilingService()

    private let queue = DispatchQueue(label: "com.walletApp.profilingService")
    private var publishers = [AnyCancellable]()
    private var isProfiling: Bool {
        get {
            return queue.sync { _isProfiling }
        }
        set {
            queue.sync { _isProfiling = newValue }
        }
    }
    private var _isProfiling = false

    func setUpProfiling(account: String, clientId: String) {
        guard !isProfiling else { return }
        isProfiling = true

        guard let token = InputConfig.mixpanelToken, !token.isEmpty  else { return }

        Mixpanel.initialize(token: token, trackAutomaticEvents: true)
        let mixpanel = Mixpanel.mainInstance()
        mixpanel.alias = account
        mixpanel.identify(distinctId: clientId)
        mixpanel.people.set(properties: ["$name": account, "account": account])

        handleLogs(from: Networking.instance.logsPublisher)
        handleLogs(from: Notify.instance.logsPublisher)
        handleLogs(from: Push.instance.logsPublisher)
        handleLogs(from: Web3Wallet.instance.logsPublisher)

    }

    private func handleLogs(from publisher: AnyPublisher<Log, Never>) {
        publisher
            .sink { [unowned self] log in
                self.queue.sync {
                    switch log {
                    case .error(let logMessage),
                         .warn(let logMessage),
                         .debug(let logMessage):
                        self.send(logMessage: logMessage)
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
