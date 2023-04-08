import Foundation

struct SyncRecord: Codable, Equatable {
    let topic: String
    let store: String
    let update: StoreUpdate

    func publicRepresentation() -> SyncUpdate {
        return SyncUpdate(store: store, update: update)
    }
}
