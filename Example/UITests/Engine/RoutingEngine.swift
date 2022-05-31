import Foundation
import XCTest

struct RoutingEngine {
    
    private var springboard: XCUIApplication {
        return App.springboard.instance
    }
    
    func cleanLaunch(app: App) {
        let app = app.instance
        app.launchArguments = ["-cleanInstall"]
        app.launch()
        app.waitForAppearence()
    }
    
    func launch(app: App) {
        app.instance.launch()
    }
    
    func activate(app: App) {
        app.instance.activate()
        app.instance.waitForAppearence()
    }
    
    func home() {
        XCUIDevice.shared.press(.home)
    }
    
    func wait(for interval: TimeInterval) {
        Thread.sleep(forTimeInterval: interval)
    }
}
