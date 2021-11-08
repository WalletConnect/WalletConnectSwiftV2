import XCTest
@testable import WalletConnect

struct SequenceStub: WCSequence {
    let topic: String
    let expiryDate: Date
}

final class SequenceStoreTests: XCTestCase {
    
    var sut: SequenceStore<SequenceStub>!
    
    var storageFake: RuntimeKeyValueStorage!
    
    override func setUp() {
        
    }
}
