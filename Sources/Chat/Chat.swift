import Foundation

/// Chat instatnce wrapper
public class Chat {

    /// Chat client instance
    public static var instance: ChatClient = {
        return ChatClientFactory.create()
    }()

    private init() { }
}
