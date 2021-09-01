// 

import Foundation

protocol RelaySubscriber: class {
    var topic: String {get set}
    func update(with jsonRpcRequest: ClientSynchJSONRPC)
}
