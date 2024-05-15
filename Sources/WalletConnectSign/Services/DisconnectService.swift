import Foundation

final class DisconnectService {
    
    enum Errors: Error {
        case sessionForTopicNotFound
    }

    private let deleteSessionService: DeleteSessionServiceProtocol
    private let sessionStorage: WCSessionStorage
    private let invalidRequestsSanitiser: InvalidRequestsSanitiserProtocol

    init(deleteSessionService: DeleteSessionServiceProtocol,
         sessionStorage: WCSessionStorage,
         invalidRequestsSanitiser: InvalidRequestsSanitiserProtocol) {
        self.deleteSessionService = deleteSessionService
        self.sessionStorage = sessionStorage
        self.invalidRequestsSanitiser = invalidRequestsSanitiser
    }

    func disconnect(topic: String) async throws {
        invalidRequestsSanitiser.removeSessionRequestsWith(topic: topic)
        
        if sessionStorage.hasSession(forTopic: topic) {
            try await deleteSessionService.delete(topic: topic)
        } else {
            throw Errors.sessionForTopicNotFound
        }
    }
}
