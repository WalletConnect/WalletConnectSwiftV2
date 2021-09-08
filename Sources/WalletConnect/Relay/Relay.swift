
import Foundation

class Relay {
    private let defaultTtl = 6*Time.hour
    private let jsonRpcSerialiser: JSONRPCSerialising
    private var transport: JSONRPCTransporting
    private let crypto: Crypto
    var subscribers = [RelaySubscriber]()

    init(jsonRpcSerialiser: JSONRPCSerialising = JSONRPCSerialiser(),
         transport: JSONRPCTransporting,
         crypto: Crypto) {
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.transport = transport
        self.crypto = crypto
        setUpTransport()
    }
    
    func publish(topic: String, payload: Encodable, subscriber: RelaySubscriber) {
        do {
            let messageJson = try payload.json()
            var message: String
            if let agreementKeys = crypto.getAgreementKeys(for: topic) {
                message = try jsonRpcSerialiser.serialise(json: messageJson, agreementKeys: agreementKeys)
            } else {
                message = messageJson.toHexEncodedString(uppercase: false)
            }
            let params = RelayJSONRPC.PublishParams(topic: topic, message: message, ttl: defaultTtl)
            let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.rawValue, params: params)
            let requestJson = try request.json()
            subscriber.set(pendingRequestId: request.id)
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
    
    func subscribe(topic: String, subscriber: RelaySubscriber) {
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
            subscriber.set(pendingRequestId: request.id)
        } catch {
            Logger.error(error)
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
            Logger.error(error)
        }
    }
    
    func addSubscriber(_ subscriber: RelaySubscriber) {
        subscribers.append(subscriber)
    }
    
    func removeSubscriber(_ subscriber: RelaySubscriber) {
        subscribers.removeAll{$0===subscriber}
    }
    
    private func setUpTransport() {
        transport.onPayload = { [unowned self] payload in
            self.onPayload(payload)
        }
    }
    
    private func onPayload(_ payload: String) {
        if let request = getSubscriptionRequest(from: payload) {
            let topic = request.params.data.topic
            if let agreementKeys = crypto.getAgreementKeys(for: topic) {
                let message = request.params.data.message
                do {
                    let deserialisedJsonRpcRequest = try jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret)
                    if let subscriber = getSubscriberFor(subscriptionId: request.params.id) {
                        subscriber.onRequest(deserialisedJsonRpcRequest)
                    }
                    let response = JSONRPCResponse(id: request.id, result: true)
                    let responseJson = try response.json()
                    transport.send(responseJson) { error in
                        if let error = error {
                            Logger.debug("Failed to Respond for request id: \(request.id)")
                            Logger.error(error)
                        }
                    }
                } catch {
                    Logger.error(error)
                }
            } else {
                Logger.debug("Did not find key associated with topic: \(topic)")
            }
        }
    }
        
    private func getSubscriptionRequest(from message: String) -> JSONRPCRequest<RelayJSONRPC.SubscriptionParams>? {
        if let data = message.data(using: .utf8),
           let request = try? JSONDecoder().decode(JSONRPCRequest<RelayJSONRPC.SubscriptionParams>.self, from: data),
           request.method == RelayJSONRPC.Method.subscription.rawValue {
            return request
        } else {
            return nil
        }
    }
    
    private func getSubscriberFor(subscriptionId: String) -> RelaySubscriber? {
        return subscribers.first{$0.isSubscribing(for: subscriptionId)}
    }
    
    private func getSubscriberFor(requestId: Int64) -> RelaySubscriber? {
        return subscribers.first{$0.hasPendingRequest(id: requestId)}

    }

}
