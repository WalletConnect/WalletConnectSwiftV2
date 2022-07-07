import Foundation

// TODO: Delete after Chat SDK integration
struct Thread: Codable {
    let topic: String
}

struct ThreadViewModel: Identifiable {
    private let thread: Thread

    init(thread: Thread) {
        self.thread = thread
    }

    var topic: String {
        return thread.topic
    }

    var id: String {
        return thread.topic
    }

    var title: String {
        return thread.topic
    }

    var subtitle: String {
        return "Chicken, Peter, you’re just a little chicken. Cheep, cheep, cheep, cheep…"
    }
}
