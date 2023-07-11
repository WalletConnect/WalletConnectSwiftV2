import Foundation

/// History instatnce wrapper
public class History {

    /// Sync client instance
    public static var instance: HistoryClient = {
        return HistoryClientFactory.create()
    }()

    private init() { }
}
