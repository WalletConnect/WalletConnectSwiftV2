import Foundation
import XCTest
@testable import WalletConnect

class SessionEngineTests: XCTestCase {
    var engine: SessionEngine!
    var relay: MockedRelay!
    var crypto: Crypto!
    var subscriber: MockedSubscriber!
    
    override func setUp() {
        crypto = Crypto(keychain: DictionaryKeychain())
        relay = MockedRelay()
        subscriber = MockedSubscriber()
        engine = SessionEngine(relay: relay, crypto: crypto, subscriber: subscriber)
    }

    override func tearDown() {
        relay = nil
        engine = nil
        crypto = nil
    }
}

