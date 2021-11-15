

import Foundation

struct JsonRpcRecord: Codable {
    let id: Int64
    let topic: String
    let chainId: String
    let request: Request
    let response: Response?
    
    struct Request: Codable {
        let method: String
        let params: AnyCodable
    }
    enum Response: Codable {
        var id: Int64 {
            switch self {
            case .error(let value):
                return value.value.id
            case .response(let value):
                return value.value.id
            }
        }
        case error(JSONRPCErrorResponse)
        case response(JSONRPCResponse<AnyCodable>)
    }
}


class JsonRpcHistory {
    let storage: KeyValueStorage<JsonRpcRecord>
    let logger: BaseLogger
    
    init(logger: BaseLogger, storage: KeyValueStorage) {
        self.logger = logger
        self.storage = storage
    }
    
    func get(id: Int64) -> JsonRpcRecord? {
        try? storage.get(key: String(id))
    }
    
    func set(topic: String, request: JSONRPCRequest<AnyCodable>) throws {
        if try? recordsStorage.get(key: request.id) ! {
            
        }
        logger.debug("Setting JSON-RPC request history record")
        recordsStorage.set(<#T##item: JsonRpcRecord##JsonRpcRecord#>, forKey: <#T##String#>)
    }
    
    func delete(dopic: String, id: Int) {
        
    }
    
    func resolve(response: JsonRpcRecord.Response) throw {
        guard let record = try? storage.get(key: String(response.id)) else { return }
        if record.response != nil {
            throw duplicate detected
        } else {
            record.response = response
        }
    }
    
    func exist(id: Int64) -> Bool {
        return (try? storage.get(key: String(id))) != nil
    }
}



final class KeyValueStorage<T> where T: Codable {

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
