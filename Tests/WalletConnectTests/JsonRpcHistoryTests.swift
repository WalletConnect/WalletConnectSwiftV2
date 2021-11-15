
import Foundation

import XCTest
import CryptoKit
@testable import WalletConnect

final class JsonRpcHistoryTests: XCTestCase {
    
    var sut: JsonRpcHistory!
    
    var fakeKeychain: KeychainServiceFake!
    
    let defaultIdentifier = "key"
    
    override func setUp() {
        sut = JsonRpcHistory(logger: MuteLogger(), storage: Dictiona)
    }
    
    override func tearDown() {
        try? sut.deleteAll()
        sut = nil
        fakeKeychain = nil
    }
}
