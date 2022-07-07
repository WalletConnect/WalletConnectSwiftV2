import Foundation
import Combine

typealias Stream<T> = AsyncPublisher<AnyPublisher<T, Never>>

final class ChatService {

    static let authorAccount: String = "TODO"

    private let messagesSubject: CurrentValueSubject<[Message], Never> = {
        return CurrentValueSubject([
            Message(message: "✨gm", authorAccount: "2", timestamp: 0),
            Message(message: "how r u man?", authorAccount: "1", timestamp: 0),
            Message(message: "good", authorAccount: "2", timestamp: 0),
            Message(message: "u?", authorAccount: "2", timestamp: 0),
            Message(message: "I’m so happy I have you as my best friend, and I love Lisa so much", authorAccount: "1", timestamp: 0),
            Message(message: "Why, Lisa, why, WHY?!", authorAccount: "2", timestamp: 0),
            Message(message: "It’s bullshit, I did not hit her. I did nooot. Oh hi, Mark!", authorAccount: "1", timestamp: 0),
            Message(message: "Johnny’s my best friend!", authorAccount: "2", timestamp: 0),
            Message(message: "Anyway, how’s your sex life?", authorAccount: "1", timestamp: 0)
        ])
    }()

    private let threadsSubject: CurrentValueSubject<[Thread], Never> = {
        return CurrentValueSubject([
            Thread(topic: "topic1"),
            Thread(topic: "topic2")
        ])
    }()

    func getMessages(topic: String) -> Stream<[Message]> {
        return messagesSubject.eraseToAnyPublisher().values
    }

    func getThreads() -> Stream<[Thread]> {
        return threadsSubject.eraseToAnyPublisher().values
    }

    func sendMessage(text: String) async throws {
        let message = Message(
            message: text,
            authorAccount: ChatService.authorAccount,
            timestamp: Int64(Date().timeIntervalSince1970)
        )
        messagesSubject.send(messagesSubject.value + [message])
    }
}
