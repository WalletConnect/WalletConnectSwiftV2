import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    //todo: universal links
//    func application(_ application: UIApplication,
//                     continue userActivity: NSUserActivity,
//                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
//    {
//        // Get URL components from the incoming user activity.
//        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
//              let incomingURL = userActivity.webpageURL,
//              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
//                  return false
//              }
//
//        // Check for specific URL components that you need.
//        guard let path = components.path,
//              let params = components.queryItems else {
//                  return false
//              }
//        return true
//    }
    

}
