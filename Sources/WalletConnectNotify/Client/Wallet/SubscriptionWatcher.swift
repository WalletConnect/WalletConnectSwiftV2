import Foundation
import Combine
import SwiftUI

class SubscriptionWatcher: ObservableObject {

    private var timerCancellable: AnyCancellable?
    private var appLifecycleCancellable: AnyCancellable?

    private let backgroundQueue = DispatchQueue(label: "com.example.subscriptionWatcher", qos: .background)

    init() {
        setupTimer()
        watchAppLifecycle()
    }

    func setupTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 5 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [unowned self] _ in
                self.backgroundQueue.async {
                    self.watchSubscriptions()
                }
            }
    }

    func watchSubscriptions() {
        
    }

    func watchAppLifecycle() {
        appLifecycleCancellable = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.setupTimer()
                self.backgroundQueue.async {
                    self.watchSubscriptions()
                }
            }
    }
}
