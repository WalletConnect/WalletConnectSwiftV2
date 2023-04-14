import UIKit
import React

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RCTBridgeDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }
    
    func sourceURL(for bridge: RCTBridge!) -> URL! {
        #if DEBUG
        return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index", fallbackExtension: nil)
        #else
        return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
        #endif
    }
}
