import UIKit
import UserNotifications
import WalletConnectNetworking
import WalletConnectEcho


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForPushNotifications()

        let notificationOption = launchOptions?[.remoteNotification]

        // 1
        if
          let notification = notificationOption as? [String: AnyObject],
          let aps = notification["aps"] as? [String: AnyObject] {
        }



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
            // Avoid networking not instantiated error by sleeping...
            Thread.sleep(forTimeInterval: 1)
            let clientId = try! Networking.interactor.getClientId()
            let deviceToken = InputConfig.simulatorIdentifier
            assert(deviceToken != "SIMULATOR_IDENTIFIER", "Please set your Simulator identifier")
            self?.registerClientWithPushServer(clientId: clientId, deviceToken: deviceToken, then: { result in
                
            })
            #endif
            //   print(result)
            // }
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
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        let clientId  = try! Networking.interactor.getClientId()
        let sanitizedClientId = clientId.replacingOccurrences(of: "did:key:", with: "")
        print(sanitizedClientId)
        print(token)

        Echo.configure(projectId: "59052d52644235f3c870aba1076a0f9e", clientId: sanitizedClientId)
        Task(priority: .high) {
            try await Echo.instance.register(deviceToken: deviceToken)
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
