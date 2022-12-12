import Foundation
import Combine

final class SessionsSubscriber {

    var onSessionsUpdate: (([Session]) -> Void)?

    private var publishers = Set<AnyCancellable>()

    init() {
        subscribeForSessionsUpdate()
    }

    func subscribeForSessionsUpdate() {
        UserDefaults.standard.publisher(for: \.sessions)
            .compactMap { $0 }
            .compactMap {
                let sessions = try? JSONDecoder().decode([WCSession].self, from: $0)
                return sessions?.map { $0.publicRepresentation() }
            }
            .sink { [weak self] sessions in
                guard let self else { return }
                self.onSessionsUpdate?(sessions)
            }
            .store(in: &publishers)
    }
}

private extension UserDefaults {

    @objc var sessions: Data? {
        get {
            data(forKey: SignStorageIdentifiers.sessions.rawValue)
        }
        set {
            set(newValue, forKey: SignStorageIdentifiers.sessions.rawValue)
        }
    }
}

