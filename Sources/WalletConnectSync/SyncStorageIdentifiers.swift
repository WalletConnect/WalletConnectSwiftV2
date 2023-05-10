import Foundation

enum SyncStorageIdentifiers {
    case index
    case object(store: String)

    var identifier: String {
        switch self {
        case .index:
            return "com.walletconnect.sync.index"
        case .object(let store):
            return "com.walletconnect.sync.object.\(store)"
        }
    }
}
