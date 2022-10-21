import Foundation

public struct RPCHistoryFactory {

    private static let networkIdentifier = "com.walletconnect.sdk.wc_jsonRpcHistoryRecord"
    private static let relayIdentifier = "com.walletconnect.sdk.relayer_client.subscription_json_rpc_record"

    public static func createForNetwork(keyValueStorage: KeyValueStorage) -> RPCHistory {
        return RPCHistoryFactory.create(keyValueStorage: keyValueStorage, identifier: RPCHistoryFactory.networkIdentifier)
    }

    public static func createForRelay(keyValueStorage: KeyValueStorage) -> RPCHistory {
        return RPCHistoryFactory.create(keyValueStorage: keyValueStorage, identifier: RPCHistoryFactory.relayIdentifier)
    }

    static func create(keyValueStorage: KeyValueStorage, identifier: String) -> RPCHistory {
        let keyValueStore = CodableStore<RPCHistory.Record>(defaults: keyValueStorage, identifier: identifier)
        return RPCHistory(keyValueStore: keyValueStore)
    }
}
