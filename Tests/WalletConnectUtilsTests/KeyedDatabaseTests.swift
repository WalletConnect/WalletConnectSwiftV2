import XCTest
import JSONRPC
import TestingUtils
@testable import WalletConnectUtils

final class KeyedDatabaseTests: XCTestCase {

    struct Object: DatabaseObject {
        let key: String
        let value: String

        var databaseId: String {
            return key
        }
    }

    let storageKey: String = "storageKey"

    var sut: KeyedDatabase<Object>!

    override func setUp() {
        sut = KeyedDatabase(storage: RuntimeKeyValueStorage(), identifier: "identifier")
    }

    override func tearDown() {
        sut = nil
    }

    func testIsChanged() throws {
        let new = Object(key: "key1", value: "value1")
        let updated = Object(key: "key1", value: "value2")

        sut.set(element: new, for: storageKey)
        sut.set(element: updated, for: storageKey)

        let value = sut.getElement(for: storageKey, id: updated.databaseId)

        XCTAssertEqual(value, updated)
    }

    func testOnUpdate() {
        let new = Object(key: "key1", value: "value1")

        var onUpdateCalled = false
        sut.onUpdate = { onUpdateCalled = true }
        sut.set(element: new, for: storageKey)

        XCTAssertTrue(onUpdateCalled)
    }
}
