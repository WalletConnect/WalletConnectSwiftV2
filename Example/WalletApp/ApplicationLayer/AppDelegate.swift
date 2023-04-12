import UIKit
import WalletConnectPush
import Combine

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private var publishers = [AnyCancellable]()
    
    static var deviceToken: Data?
    static var registrationLogs: String = ""
    
    private let app = Application()

    private var configurators: [Configurator] {
        return [
            MigrationConfigurator(app: app),
            ThirdPartyConfigurator(),
            ApplicationConfigurator(app: app),
            AppearanceConfigurator()
        ]
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-disableAnimations") {
            UIView.setAnimationsEnabled(false)
            UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .last { $0.isKeyWindow }?.layer.speed = 200
        }
        #endif
    
        
        ThirdPartyConfigurator().configure()
        PushRegisterer().registerForPushNotifications()
        
        Networking.interactor.socketConnectionStatusPublisher
            .first {$0  == .connected}
            .sink{ [weak self] status in
                guard let deviceToken = AppDelegate.deviceToken else {
                    return
                }
                Task(priority: .high) {
                    
                    AppDelegate.registrationLogs.append("socket connected registering token \n")
                    
                    try await Push.wallet.register(deviceToken: deviceToken)
                }
            }.store(in: &self.publishers)
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        
        AppDelegate.deviceToken = deviceToken
        
        Task(priority: .high) {
            // Commenting this out as it breaks UI tests that copy/paste URI
            // Use pasteboard for testing purposes
            // let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
            // let token = tokenParts.joined()
            // let pasteboard = UIPasteboard.general
            // pasteboard.string = token
            AppDelegate.registrationLogs.append("didRegisterWithDeviceToken registering token \n")
            
            try await Push.wallet.register(deviceToken: deviceToken)
        }
    }

    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        
        
        AppDelegate.registrationLogs.append("didFailToRegisterWithError registering token \(error.localizedDescription) \n")
    }

}
