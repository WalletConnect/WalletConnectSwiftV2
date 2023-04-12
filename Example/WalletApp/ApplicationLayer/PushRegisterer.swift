
import WalletConnectPush
import Combine
import UIKit

class PushRegisterer {

    private var publishers = [AnyCancellable]()

    func getNotificationSettings() {
        
        AppDelegate.registrationLogs.append("getNotificationSettings \n")
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            
            AppDelegate.registrationLogs.append("Notification settings: \(settings.authorizationStatus) \n")
            
            guard settings.authorizationStatus == .authorized else { return }
            
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func registerForPushNotifications() {
        
        AppDelegate.registrationLogs.append("requestAuthorization \n")
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: [.alert, .sound, .badge]) { granted, error in
            print("Permission granted: \(granted)")
                
                AppDelegate.registrationLogs.append("registerForPushNotifications granted: \(granted) error: \(error?.localizedDescription) \n")
                
                guard granted else { return }
                self.getNotificationSettings()
#if targetEnvironment(simulator)
//                Networking.interactor.socketConnectionStatusPublisher
//                    .first {$0  == .connected}
//                    .sink{ status in
//                        let deviceToken = InputConfig.simulatorIdentifier
//                        assert(!deviceToken.isEmpty && deviceToken != "SIMULATOR_IDENTIFIER", "Please set your Simulator identifier")
//                        Task(priority: .high) {
//                            try await Push.wallet.register(deviceToken: deviceToken)
//                        }
//                    }.store(in: &self!.publishers)
#endif
            }
    }
}
