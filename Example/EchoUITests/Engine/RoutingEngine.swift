import Foundation
import XCTest

struct RoutingEngine {

    var springboard: XCUIApplication {
        return App.springboard.instance
    }

    func launch(app: App, clean: Bool) {
        app.instance.terminate()

        if clean {
            let app = app.instance
            app.launchArguments = ["-cleanInstall", "-disableAnimations"]
            app.launch()
        } else {
            let app = app.instance
            app.launch()
        }
    }

    func activate(app: App) {
        let app = app.instance
        app.activate()
        app.wait(until: \.exists)
    }

    func wait(for interval: TimeInterval) {
        Thread.sleep(forTimeInterval: interval)
    }
}
