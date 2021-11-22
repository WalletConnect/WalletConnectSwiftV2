
import Foundation
import XCTest
@testable import WalletConnect

class SessionEngineTests: XCTestCase {
    var engine: SessionEngine!
    var relay: MockedWCRelay!
    var crypto: Crypto!
    var subscriber: MockedSubscriber!
    
    override func setUp() {
        crypto = Crypto(keychain: KeychainStorageMock())
        relay = MockedWCRelay()
        subscriber = MockedSubscriber()
        let meta = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        let logger = ConsoleLogger()
        let store = SequenceStore<SessionSequence>(storage: RuntimeKeyValueStorage())
        engine = SessionEngine(relay: relay, crypto: crypto, subscriber: subscriber, sequencesStore: store, isController: false, metadata: meta, logger: logger)
    }

    override func tearDown() {
        relay = nil
        engine = nil
        crypto = nil
    }
}

