
import Foundation
import WalletConnectUtils

class JsonRpcHistoryRecordingMock: JsonRpcHistoryRecording {
    func get(id: Int64) -> JsonRpcRecord? {
        return nil
    }
    
    func set(topic: String, request: JSONRPCRequest<AnyCodable>) throws {
    }
    
    func delete(topic: String) {
    }
    
    func resolve(response: JsonRpcResponseTypes) throws {
    }
    
    func exist(id: Int64) -> Bool {
        return false
    }
    
    
}
