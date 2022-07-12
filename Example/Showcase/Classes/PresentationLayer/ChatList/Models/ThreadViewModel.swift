import Foundation
import Chat

struct ThreadViewModel: Identifiable {
    let thread: Chat.Thread

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
