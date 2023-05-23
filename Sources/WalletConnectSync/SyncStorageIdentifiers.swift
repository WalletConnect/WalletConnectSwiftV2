import Foundation

enum SyncStorageIdentifiers {
    case index
    case history
    case object(store: String)

    var identifier: String {
        switch self {
        case .index:
            return "com.walletconnect.sync.index"
        case .history:
            return "com.walletconnect.sync.history"
        case .object(let store):
            return "com.walletconnect.sync.object.\(store)"
        }
    }
}
