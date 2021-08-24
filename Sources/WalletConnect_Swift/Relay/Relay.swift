//

import Foundation


class Relay {
    private let defaultTtl = Time.sixHours
    private let jsonRpcSerialiser: JSONRPCSerialiser
    private let transport: JSONRPCTransporting
    private let crypto: Crypto

    init(jsonRpcSerialiser: JSONRPCSerialiser = JSONRPCSerialiser(),
         transport: JSONRPCTransporting,
         crypto: Crypto) {
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.transport = transport
        self.crypto = crypto
    }
    
    func publish(topic: String, payload: Encodable) {
        guard let agreementKeys = crypto.getAgreementKeys(for: topic) else {return}
        do {
            let messageJson = try payload.json()
            let message = try jsonRpcSerialiser.serialise(json: messageJson, agreementKeys: agreementKeys)
            let params = RelayJSONRPC.PublishParams(topic: topic, message: message, ttl: defaultTtl)
            let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.rawValue, params: params)
            let requestJson = try request.json()
            transport.send(requestJson)
        } catch {
            Logger.debug(error)
        }
    }
    
    func subscribe(topic: String) {
        let params = RelayJSONRPC.SubscribeParams(topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.subscribe.rawValue, params: params)
        do {
            let requestJson = try request.json()
            transport.send(requestJson)
        } catch {
            Logger.debug(error)
        }
    }
    
    func unsubscribe() {
        
    }
}

