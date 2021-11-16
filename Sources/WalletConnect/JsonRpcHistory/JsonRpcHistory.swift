
import Foundation

class JsonRpcHistory {
    let storage: KeyValueStore<JsonRpcRecord>
    let logger: BaseLogger
    
    init(logger: BaseLogger, keyValueStorage: KeyValueStorage) {
        self.logger = logger
        self.storage = KeyValueStore<JsonRpcRecord>(defaults: keyValueStorage)
    }
    
    func get(id: Int64) -> JsonRpcRecord? {
        try? storage.get(key: getKey(for: id))
    }
    
    func set(topic: String, request: ClientSynchJSONRPC, chainId: String) throws {
        guard !exist(id: request.id) else {
            throw WalletConnectError.internal(.jsonRpcDuplicateDetected)
        }
        logger.debug("Setting JSON-RPC request history record")
        let record = JsonRpcRecord(id: request.id, topic: topic, chainId: chainId, request: JsonRpcRecord.Request(method: request.method, params: request.params), response: nil)
        try storage.set(record, forKey: getKey(for: request.id))
    }
    
    func delete(id: Int64) {
        storage.delete(forKey: getKey(for: id))
    }
    
    func resolve(response: JsonRpcResponseTypes) throws {
        guard var record = try? storage.get(key: getKey(for: response.id)) else { return }
        if record.response != nil {
            throw WalletConnectError.internal(.jsonRpcDuplicateDetected)
        } else {
            record.response = response
            try storage.set(record, forKey: getKey(for: record.id))
        }
    }
    
    func exist(id: Int64) -> Bool {
        return (try? storage.get(key: getKey(for: id))) != nil
    }
    
    private func getKey(for id: Int64) -> String {
        return "wc_json_rpc_record_\(id)"
    }
}
