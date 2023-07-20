import Foundation

final class RecentWalletsStorage {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var recentWallets: [Listing] {
        get {
            guard
                let data = defaults.data(forKey: "recentWallets"),
                let wallets = try? JSONDecoder().decode([Listing].self, from: data)
            else {
                return []
            }
            
            return wallets
        }
        set {
            guard
                let walletsData = try? JSONEncoder().encode(newValue)
            else {
                return
            }
            
            defaults.set(walletsData, forKey: "recentWallets")
        }
    }
}
