import Foundation
import Combine

protocol NotificationPublishing {
    func publisher(for name: NSNotification.Name) -> AnyPublisher<Notification, Never>
}

extension NotificationCenter: NotificationPublishing {
    func publisher(for name: NSNotification.Name) -> AnyPublisher<Notification, Never> {
        return publisher(for: name, object: nil).eraseToAnyPublisher()
    }
}

#if DEBUG
class MockNotificationCenter: NotificationPublishing {
    private let subject = PassthroughSubject<Notification, Never>()

    func publisher(for name: NSNotification.Name) -> AnyPublisher<Notification, Never> {
        return subject.eraseToAnyPublisher()
    }

    func post(name: NSNotification.Name) {
        subject.send(Notification(name: name))
    }
}
#endif

