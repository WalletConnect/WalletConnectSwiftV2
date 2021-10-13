import XCTest
@testable import WalletConnect

final class SecureStorageTests: XCTestCase {

    var sut: SecureStorage!
    
    var keychainMock: KeychainStorageMock!
    
    var testQueue: DispatchQueue!
    
    override func setUp() {
        testQueue = DispatchQueue(label: "queue.test.storage")
        keychainMock = KeychainStorageMock()
        sut = SecureStorage(keychain: keychainMock, dispatchQueue: testQueue)
    }
    
    override func tearDown() {
        sut = nil
        keychainMock = nil
        testQueue = nil
    }
    
    func testSet() {
        sut.set("", forKey: "")
        testQueue.sync {
            XCTAssertTrue(keychainMock.didCallAdd)
        }
    }
    
    func testGet() {
        let _: String? = sut.get(key: "")
        testQueue.sync {
            XCTAssertTrue(keychainMock.didCallRead)
        }
    }
    
    func testRemoveValue() {
        sut.removeValue(forKey: "")
        testQueue.sync {
            XCTAssertTrue(keychainMock.didCallDelete)
        }
    }
    
    func testThreadSafety() {
        let count = 1000
        DispatchQueue.concurrentPerform(iterations: count) { i in
            let key = "key\(i)"
            let value = UUID().uuidString
            sut.set(value, forKey: key)
            let retrievedValue: String? = sut.get(key: key)
            sut.removeValue(forKey: key)
            let retrievedAfterDelete: String? = sut.get(key: key)
            XCTAssertEqual(retrievedValue, value)
            XCTAssertNil(retrievedAfterDelete)
        }
    }
}

final class KeychainStorageMock: KeychainStorageProtocol {
    
    var storage: [String: Data] = [:]
    
    private(set) var didCallAdd = false
    private(set) var didCallRead = false
    private(set) var didCallDelete = false
    
    func add<T>(_ item: T, forKey key: String) throws where T : GenericPasswordConvertible {
        didCallAdd = true
        storage[key] = item.rawRepresentation
    }
    
    func read<T>(key: String) throws -> T where T : GenericPasswordConvertible {
        didCallRead = true
        if let data = storage[key] {
            return try T(rawRepresentation: data)
        }
        throw WalletConnectError.notApproved
    }
    
    func delete(key: String) throws {
        didCallDelete = true
        storage[key] = nil
    }
}
