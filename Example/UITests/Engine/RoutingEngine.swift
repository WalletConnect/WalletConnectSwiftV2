import Foundation
import XCTest

struct RoutingEngine {
    
    private var springboard: XCUIApplication {
        return App.springboard.instance
    }
    
    func open(app: App) {
        app.instance.launch()
    }
    
    func home() {
        XCUIDevice.shared.press(.home)
    }
    
    func wait(for interval: TimeInterval) {
        Thread.sleep(forTimeInterval: interval)
    }
    
    func delete(app: App) {
        app.instance.terminate()

        let icon = springboard.icons[app.displayName]

        if icon.exists {
            icon.press(forDuration: 1)

            let buttonRemoveApp = springboard.buttons["Remove App"]
            if buttonRemoveApp.waitForExistence(timeout: 5) {
                buttonRemoveApp.tap()
            } else {
                XCTFail("Button \"Remove App\" not found")
            }

            let buttonDeleteApp = springboard.alerts.buttons["Delete App"]
            if buttonDeleteApp.waitForExistence(timeout: 5) {
                buttonDeleteApp.tap()
            } else {
                XCTFail("Button \"Delete App\" not found")
            }

            let buttonDelete = springboard.alerts.buttons["Delete"]
            if buttonDelete.waitForExistence(timeout: 5) {
                buttonDelete.tap()
            } else {
                XCTFail("Button \"Delete\" not found")
            }
        }
    }
}
