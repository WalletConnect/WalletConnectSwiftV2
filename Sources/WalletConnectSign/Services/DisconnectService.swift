import Foundation

class DisconnectService {
    enum Errors: Error {
        case sessionForTopicNotFound
    }

    private let deleteSessionService: DeleteSessionService
    private let sessionStorage: WCSessionStorage

    init(deleteSessionService: DeleteSessionService,
         sessionStorage: WCSessionStorage) {
        self.deleteSessionService = deleteSessionService
        self.sessionStorage = sessionStorage
    }

    func disconnect(topic: String) async throws {
        if sessionStorage.hasSession(forTopic: topic) {
            try await deleteSessionService.delete(topic: topic)
        } else {
            throw Errors.sessionForTopicNotFound
        }
    }
}
