import UIKit
import WalletConnectSign

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        ProfilingService.instance.send(logMessage: .init(message: "AppDelegate: application will enter foreground"))
        // Additional code to handle entering the foreground
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        ProfilingService.instance.send(logMessage: .init(message: "AppDelegate: application did become active"))
        // Additional code to handle becoming active
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) async -> Bool {
        ProfilingService.instance.send(logMessage: .init(message: "AppDelegate: will try to dispatch envelope: \(String(describing: userActivity.webpageURL))"))
        guard let url = userActivity.webpageURL,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return true
        }
        try! Sign.instance.dispatchEnvelope(url.absoluteString)

        return true
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Log the event of opening the app via URL
        ProfilingService.instance.send(logMessage: .init(message: "AppDelegate: app opened by URL: \(url.absoluteString)"))

        // Handle the URL appropriately
        try! Sign.instance.dispatchEnvelope(url.absoluteString)

        return true
    }
}
