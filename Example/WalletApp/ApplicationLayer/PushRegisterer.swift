
import WalletConnectPush
import Combine
import UIKit

class PushRegisterer {

    private var publishers = [AnyCancellable]()

    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
          guard settings.authorizationStatus == .authorized else { return }
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
          }
      }
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
#if targetEnvironment(simulator)
                Networking.interactor.socketConnectionStatusPublisher
                    .first {$0  == .connected}
                    .sink{ status in
                        let deviceToken = InputConfig.simulatorIdentifier
                        assert(deviceToken != "SIMULATOR_IDENTIFIER", "Please set your Simulator identifier")
                        Task(priority: .high) {
                            try await Push.wallet.register(deviceToken: deviceToken)
                        }
                    }.store(in: &self!.publishers)
#endif
            }
    }
}
