//

import Foundation

protocol Subscriber {
    var topic: String {get set}
}
class Relay {
    private let defaultTtl = Time.sixHours
    private let jsonRpcSerialiser: JSONRPCSerialiser
    private var transport: JSONRPCTransporting
    private let crypto: Crypto
//    var subscribers: [Subscriber]

    init(jsonRpcSerialiser: JSONRPCSerialiser = JSONRPCSerialiser(),
         transport: JSONRPCTransporting,
         crypto: Crypto) {
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.transport = transport
        self.crypto = crypto
        setUpTransport()
    }
    
    func publish(topic: String, payload: Encodable) {
        guard let agreementKeys = crypto.getAgreementKeys(for: topic) else {return}
        do {
            let messageJson = try payload.json()
            let message = try jsonRpcSerialiser.serialise(json: messageJson, agreementKeys: agreementKeys)
            let params = RelayJSONRPC.PublishParams(topic: topic, message: message, ttl: defaultTtl)
            let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.rawValue, params: params)
            let requestJson = try request.json()
            print(messageJson)
            print(requestJson)
            Logger.debug("Publishing Payload on Topic: \(topic)")
            transport.send(requestJson) { error in
                if let error = error {
                    Logger.debug("Failed to Publish Payload")
                    Logger.error(error)
                }
            }
        } catch {
            Logger.debug(error)
        }
    }
    
    func subscribe(topic: String) {
        Logger.debug("Subscribing on Topic: \(topic)")
        let params = RelayJSONRPC.SubscribeParams(topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.subscribe.rawValue, params: params)
        do {
            let requestJson = try request.json()
            transport.send(requestJson) { error in
                if let error = error {
                    Logger.debug("Failed to Subscribe on Topic")
                    Logger.error(error)
                }
            }
        } catch {
            Logger.debug(error)
        }
    }
    
    func unsubscribe(topic: String, id: String) {
        Logger.debug("Unsubscribing on Topic: \(topic)")
        let params = RelayJSONRPC.UnsubscribeParams(id: id, topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.unsubscribe.rawValue, params: params)
        do {
            let requestJson = try request.json()
            transport.send(requestJson) { error in
                if let error = error {
                    Logger.debug("Failed to Unsubscribe on Topic")
                    Logger.error(error)
                }
            }
        } catch {
            Logger.debug(error)
        }
    }
    
    func addSubscriber() {
        
    }
    
    func removeSubscriber() {
        
    }
    
    private func setUpTransport() {
        transport.onMessage = { message in
            if let data = message.data(using: .utf8),
               let request = try? JSONDecoder().decode(JSONRPCRequest<RelayJSONRPC.SubscriptionParams>.self, from: data),
               request.method == RelayJSONRPC.Method.subscription.rawValue {
//                let topic = request.params.data.topic
//                if let agreementKeys = crypto.getAgreementKeys(for: topic) {
//                    let deserialisedJsonRpcRequest = jsonRpcSerialiser.deserialise(message: request.params.data.message, symmetricKey: agreementKeys.sharedSecret)
//                    if let subscriber = getSubscriber(for: topic) {
//                        subscriber
//                    }
//                } else {
//                    Logger.debug("Did not find key associated with topic: \(topic)")
//                }
            }
        }
    }
    
//    private func getSubscriber(for topic: String) -> Subscriber? {
//
//    }
}

