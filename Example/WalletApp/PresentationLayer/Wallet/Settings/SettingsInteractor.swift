import Foundation
import WalletConnectNotify

final class SettingsInteractor {

    func notifyUnregister(account: Account) async throws {
        try await Notify.instance.unregister(account: account)
    }
}
