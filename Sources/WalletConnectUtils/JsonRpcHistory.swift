
import Foundation

public protocol JsonRpcHistoryRecording {
    func get(id: Int64) -> JsonRpcRecord?
    func set(topic: String, request: JSONRPCRequest<AnyCodable>) throws
    func delete(topic: String)
    func resolve(response: JsonRpcResponseTypes) throws
    func exist(id: Int64) -> Bool
}

public class JsonRpcHistory: JsonRpcHistoryRecording {
    enum RecordingError: Error {
        case jsonRpcDuplicateDetected
    }
    let storage: KeyValueStore<JsonRpcRecord>
    let logger: ConsoleLogging
    let identifier: String
    
    public init(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, uniqueIdentifier: String? = nil) {
        self.logger = logger
        self.storage = KeyValueStore<JsonRpcRecord>(defaults: keyValueStorage)
        self.identifier = "com.walletconnect.sdk.\(uniqueIdentifier ?? "")"
    }
    
    public func get(id: Int64) -> JsonRpcRecord? {
        try? storage.get(key: getKey(for: id))
    }
    
    public func set(topic: String, request: JSONRPCRequest<AnyCodable>) throws {
        guard !exist(id: request.id) else {
            throw RecordingError.jsonRpcDuplicateDetected
        }
        logger.debug("Setting JSON-RPC request history record")
        let record = JsonRpcRecord(id: request.id, topic: topic, request: JsonRpcRecord.Request(method: request.method, params: request.params), response: nil)
        try storage.set(record, forKey: getKey(for: request.id))
    }
    
    public func delete(topic: String) {
        storage.getAll().forEach { record in
            if record.topic == topic {
                storage.delete(forKey: getKey(for: record.id))
            }
        }
    }
    
    public func resolve(response: JsonRpcResponseTypes) throws {
        guard var record = try? storage.get(key: getKey(for: response.id)) else { return }
        if record.response != nil {
            throw RecordingError.jsonRpcDuplicateDetected
        } else {
            record.response = response
            try storage.set(record, forKey: getKey(for: record.id))
        }
    }
    
    public func exist(id: Int64) -> Bool {
        return (try? storage.get(key: getKey(for: id))) != nil
    }
    
    private func getKey(for id: Int64) -> String {
        let prefix = "\(identifier).wc_json_rpc_record."
        return "\(prefix)\(id)"
    }
}
