

import Foundation

struct JsonRpcRecord: Codable {
    let id: Int64
    let topic: String
    let chainId: String?
    let request: Request
    var response: Response?
    
    struct Request: Codable {
        let method: String
        let params: AnyCodable
    }
    enum Response: Codable {
        var id: Int64 {
            switch self {
            case .error(let value):
                return value.id
            case .response(let value):
                return value.id
            }
        }
        case error(JSONRPCErrorResponse)
        case response(JSONRPCResponse<AnyCodable>)
    }
}


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
    
    func set(topic: String, request: JSONRPCRequest<AnyCodable>, chainId: String) throws {
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
    
    func resolve(response: JsonRpcRecord.Response) throws {
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



final class KeyValueStore<T> where T: Codable {
    private let defaults: KeyValueStorage

    init(defaults: KeyValueStorage) {
        self.defaults = defaults
    }

    func set(_ item: T, forKey key: String) throws {
        let encoded = try JSONEncoder().encode(item)
        defaults.set(encoded, forKey: key)
    }

    func get(key: String) throws -> T? {
        guard let data = defaults.object(forKey: key) as? Data else { return nil }
        let item = try JSONDecoder().decode(T.self, from: data)
        return item
    }

    func getAll() -> [T] {
        return defaults.dictionaryRepresentation().compactMap {
            if let data = $0.value as? Data,
               let item = try? JSONDecoder().decode(T.self, from: data) {
                return item
            }
            return nil
        }
    }

    func delete(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
