import XCTest
@testable import WalletConnect

let defaultTimeout: TimeInterval = 5.0

func randomTopic() -> String {
    "\(UUID().uuidString)\(UUID().uuidString)".replacingOccurrences(of: "-", with: "").lowercased()
}

final class RelayTests: XCTestCase {
    
    let url = URL(string: "wss://staging.walletconnect.org")!
    
    func makeRelay() -> Relay {
        let transport = JSONRPCTransport(url: url)
        return Relay(transport: transport, crypto: Crypto())
    }
    
    func testSubscribe() {
        let expectation = expectation(description: "subscribe call must succeed")
        
        let relay = makeRelay()
        
        print("Subscribing relay A")
        _ = try? relay.subscribe(topic: randomTopic()) { result in
            print("Relay A Subscribe result: \(result)")
            switch result {
            case .success(let subID):
                print("Sub success A")
                expectation.fulfill()
            case .failure(let error):
                print("ERROR: \(error)")
                XCTFail()
            }
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testConnect() {
        let expect = expectation(description: "subs call must succeed")
        
//        let url1 = url//URL(string: "wss://staging.walletconnect.org?apiKey=c4f79cc821944d9680842e34466bfbd")!
//        let url2 = url//URL(string: "wss://staging.walletconnect.org?apiKey=c4f79cc821944d9680842e34466bfbe")!
//        let transportA = JSONRPCTransport(url: url1)
//        let relayA = Relay(transport: transportA, crypto: Crypto())
//
//        let transportB = JSONRPCTransport(url: url2)
//        let relayB = Relay(transport: transportB, crypto: Crypto())
        
        let relayA = makeRelay()
        let relayB = makeRelay()
        
        let topic = "8097df5f14871126866252c1b7479a14aefb980188fc35ec97d130d24bd887b3"
        
        let canc = relayB.clientSynchJsonRpcPublisher.sink { jsonRPC in
            if case .pairingApprove(let params) = jsonRPC.params {
                print("Received subscription: \(params)")
                expect.fulfill()
            }
        }
        
//        let sema = DispatchSemaphore(value: 0)
        
//        transportA.onConnect = {
//            print("Connect transport A")
////            sema.signal()
//        }
//        transportB.onConnect = {
//            print("Connect transport B")
////            sema.signal()
//        }
//        sema.wait()
//        sema.wait()
        
        let grp = DispatchGroup()
        
        grp.enter()
        print("Subscribing relay A")
        _ = try! relayA.subscribe(topic: topic) { result in
            print("Relay A Subscribe result: \(result)")
            switch result {
            case .success(let subID):
                print("Sub success A")
//                sema.signal()
            case .failure(let error):
                print("ERROR: \(error)")
                XCTFail()
            }
            grp.leave()
        }
//        sema.wait()
        
        grp.enter()
        print("Subscribing relay B")
        _ = try! relayB.subscribe(topic: topic) { result in
            print("Relay B Subscribe result: \(result)")
            switch result {
            case .success(let subID):
                print("Sub success B")
//                sema.signal()
            case .failure(let error):
                print("ERROR: \(error)")
                XCTFail()
            }
            grp.leave()
        }
        grp.wait(timeout: .now() + 5.0)
//        sema.wait()
        
        print("Publishing payload")
//        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            let params = PairingType.ApproveParams(
                topic: "", relay: RelayProtocolOptions(protocol: "", params: nil), responder: PairingType.Participant(publicKey: ""), expiry: 0, state: nil)
            let syncMethod = ClientSynchJSONRPC(method: .pairingApprove, params: .pairingApprove(params))
//            let payload = String(data: try! JSONEncoder().encode(syncMethod), encoding: .utf8)!
            let
            _ = try? relayA.publish(topic: topic, payload: syncMethod) { result in
                print("Publish message result: \(result)")
            }
//        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        print()
    }
    
    
    
    // - Working socket
    
    func testSocket() {
        let expect = expectation(description: "")
        
        let topic = randomTopic()
        let url = URL(string: "wss://staging.walletconnect.org")!
        
        let sessionA = URLSession(configuration: .default)
        let socketA = WebSocketSession(session: sessionA)
        
        let sessionB = URLSession(configuration: .default)
        let socketB = WebSocketSession(session: sessionB)
        
        socketA.onMessageReceived = { message in
            print("[SOCKET A] Message: \(message)")
            if let _ = try? JSONDecoder().decode(SubResult.self, from: message.data(using: .utf8)!) {
                print("Sending payload")
                let payload = PubRequest.withTopic(topic, msg: "Hello server").json()
                socketA.send(payload)
            }
        }
        socketA.onError = {
            print("[SOCKET A] Error: \($0)")
        }
        
        socketB.onMessageReceived = { message in
            print("[SOCKET B] Message: \(message)")
            if let payload = try? JSONDecoder().decode(Subscription.self, from: message.data(using: .utf8)!) {
                print("Received subscription message payload: \(payload.params.data.message)")
                expect.fulfill()
            }
        }
        socketB.onError = {
            print("[SOCKET B] Error: \($0)")
        }
        
        socketA.connect(on: url)
        socketB.connect(on: url)
        
        let reqA = SubRequest.withTopic(topic).json()
        let reqB = SubRequest.withTopic(topic).json()
        print("Request A: \(reqA)")
        print("Request B: \(reqB)")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            socketA.send(reqA)
            socketB.send(reqB)
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        print("\nEND\n")
    }
}

struct SubRequest: Encodable {
    let id: Int64
    let jsonrpc: String
    let method: String
    let params: Params
    
    struct Params: Encodable {
        let topic: String
    }
    
    static func withTopic(_ t: String) -> SubRequest {
        SubRequest(
            id: Int64(Date().timeIntervalSince1970 * 1000)*1000 + Int64.random(in: 0..<1000),
            jsonrpc: "2.0", method: "waku_subscribe", params: Params(topic: t))
    }
    
    func json() -> String {
        let data = try! JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

struct SubResult: Decodable {
    let id: Int64
    let jsonrpc: String
    let result: String
}

struct PubRequest: Encodable {
    let id: Int64
    let jsonrpc: String
    let method: String
    let params: Params
    
    struct Params: Encodable {
        let topic: String
        let message: String
        let ttl: Int64
    }
    
    static func withTopic(_ t: String, msg: String) -> PubRequest {
        PubRequest(
            id: Int64(Date().timeIntervalSince1970 * 1000)*1000 + Int64.random(in: 0..<1000),
            jsonrpc: "2.0", method: "waku_publish",
            params: Params(topic: t, message: msg, ttl: Int64(Time.day)))
    }
    
    func json() -> String {
        let data = try! JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

struct Subscription: Decodable {
    let id: Int64
    let jsonrpc: String
    let method: String
    let params: Params

    struct Params: Decodable {
        let id: String
        let data: SubData
    }
    
    struct SubData: Decodable {
        let topic: String
        let message: String
    }
}
