import Foundation

final class RecentWalletsStorage {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var recentWallets: [Listing] {
        get {
            loadRecentWallets()
        }
        set {
            saveRecentWallets(newValue)
        }
    }
    
    func loadRecentWallets() -> [Listing] {
        guard
            let data = defaults.data(forKey: "recentWallets"),
            let wallets = try? JSONDecoder().decode([Listing].self, from: data)
        else {
            return []
        }
        
        return wallets.filter { listing in
            guard let lastTimeUsed = listing.lastTimeUsed else {
                assertionFailure("Shouldn't happen we stored wallet without `lastTimeUsed`")
                return false
            }
            
            // Consider Recent only for 3 days
            return abs(lastTimeUsed.timeIntervalSinceNow) > (24 * 60 * 60 * 3)
        }
    }
    
    func saveRecentWallets(_ listings: [Listing])  {
        
        let subset = Array(listings.filter {
            $0.lastTimeUsed != nil
        }.prefix(5))
        
        guard
            let walletsData = try? JSONEncoder().encode(subset)
        else {
            return
        }
        
        defaults.set(walletsData, forKey: "recentWallets")
    }
}
