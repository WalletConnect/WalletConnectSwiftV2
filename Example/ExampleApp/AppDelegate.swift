import UIKit
import UserNotifications
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectPush
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var publishers = [AnyCancellable]()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForPushNotifications()


        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"])

        Networking.configure(projectId: InputConfig.projectId, socketFactory: DefaultSocketFactory())
        Pair.configure(metadata: metadata)

        Push.configure()
        Push.wallet.requestPublisher.sink { (id: RPCID, account: Account, metadata: AppMetadata) in
            Task(priority: .high) { try! await Push.wallet.approve(id: id) }
        }.store(in: &publishers)

        Push.wallet.pushMessagePublisher.sink { pm in
            print(pm)
        }.store(in: &publishers)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

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

    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }

    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task(priority: .high) {
            try await Push.wallet.register(deviceToken: deviceToken)
        }
    }

    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // TODO: when is this invoked?
        print("Failed to register: \(error)")
    }
}

