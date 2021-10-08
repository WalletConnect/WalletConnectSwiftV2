import XCTest
@testable import WalletConnect

final class KeychainStorageTests: XCTestCase {
    
    var keychain: KeychainStorage!
    
    override class func setUp() {
        
    }
    
    override func setUp() {
        keychain = KeychainStorage()
    }
    
    override class func tearDown() {
        
    }
    
    override func tearDown() {
        keychain = nil
    }
    
    let data = "data".data(using: .utf8)!
    let key = "0x45ab3a5ecf6fe6ea78efc07ae"
    
    func testStorage() {
//        let del = keychain.delete(key: key)
        let add1 = keychain.add(data, forKey: key)
//        let add2 = keychain.add(data, forKey: key)
        
        let read = keychain.read(forKey: key)
        let del2 = keychain.delete(key: key)
        
//        XCTAssertTrue(del)
        XCTAssertTrue(add1)
//        XCTAssertTrue(add2)
        XCTAssertNotNil(read)
        XCTAssertEqual(read, data)
        XCTAssertTrue(del2)
    }
}
