
import Foundation

enum StorageDomainIdentifiers {
    static func jsonRpcHistory(clientName: String) -> String {
        return "com.walletconnect.sdk.\(clientName).wc_jsonRpcHistoryRecord"
    }
    static func pairings(clientName: String) -> String {
        return "com.walletconnect.sdk.\(clientName).pairingSequences"
    }
    static func sessions(clientName: String) -> String {
        return "com.walletconnect.sdk.\(clientName).sessionSequences"
    }
}
