import XCTest
@testable import WalletConnect

class AnyCodableTests: XCTestCase {

    func testCodingBool() {
        [true, false].forEach { bool in
            do {
                let anyCodable = AnyCodable(bool)
                let encoded = try JSONEncoder().encode(anyCodable)
                let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
                let codingResult = decoded.value as? Bool
                XCTAssertEqual(bool, codingResult)
            } catch {
                XCTFail()
            }
        }
    }
    
    func testCodingStruct() {
        do {
            let aaa = EthTransaction.make("0xbeef")
            let value = AnyCodable(aaa)
            let encoded = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            let obj = decoded.get(EthTransaction.self)
            XCTAssertEqual(aaa, obj)
        } catch {
            XCTFail()
        }
    }
    
    func testMore() {
        let dict: [String: String] = [
            "from": "0xb60e8dd61c5d32be8058bb8eb970870f07233155",
            "to": "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
            "data":
              "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
            "gasLimit": "0x76c0",
            "gasPrice": "0x9184e72a000",
            "value": "0x9184e72a",
            "nonce": "0x117"
        ]
        let data = try! JSONSerialization.data(withJSONObject: dict, options: [.fragmentsAllowed])
        
        let string1 = """
{
    "from": "0xb60e8dd61c5d32be8058bb8eb970870f07233155",
    "to": "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
    "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
    "gasLimit": "0x76c0",
    "gasPrice": "0x9184e72a000",
    "value": "0x9184e72a",
    "nonce": "0x117"
}
"""
//        let data = string1.data(using: .utf8)!
        let decoded = try! JSONDecoder().decode(AnyCodable.self, from: data)
        let encoded = try! JSONEncoder().encode(decoded)
        let model = try? JSONDecoder().decode(EthTransaction.self, from: encoded)
        let dict2 = try? JSONSerialization.jsonObject(with: encoded, options: [.allowFragments]) as? [String: String]
        XCTAssertEqual(dict, dict2)
        XCTAssertNotNil(model)
        print()
        print("Strings:")
        print()
        print(string1)
        print()
//        print(str)
        print()
    }
    
    func testDecodingStruct() {
        let data = """
{
    "from": "0xb60e8dd61c5d32be8058bb8eb970870f07233155",
    "to": "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
    "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
    "gas": "0x76c0",
    "gasPrice": "0x9184e72a000",
    "value": "0x9184e72a",
    "nonce": "0x117"
}
""".data(using: .utf8)!
        
        let decoded = try! JSONDecoder().decode(AnyCodable.self, from: data)
        print()
        print("\(decoded.value)")
        print()
//        XCTAssertNotNil(decoded)
        let castDict = decoded.value as? [String: Any]
        print("Cast to dictionary: \(castDict)")
        print()
        let castStruct = decoded.value as? EthTransaction
        print("Cast to struct: \(castStruct)")
        print()
    }
    
    func testCodingStructArray() {
        do {
            let e1 = EthTransaction.make("0x1234")
            let e2 = EthTransaction.make("0x9876")
            let array = [e1, e2]
            let value = AnyCodable(array)
            let encoded = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            let cast = decoded.get([EthTransaction].self)
            XCTAssertNotNil(cast)
        } catch {
            XCTFail()
        }
    }
    
    func testDecodeBool() {
//        let data = """
//{
//    true
//}
//""".data(using: .utf8)!
        let data = "true".data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertNotNil(decoded)
        let cast = decoded?.value as? Bool
        XCTAssertNotNil(cast)
    }
    
    func testEncodeInt() {
        let codable = AnyCodable(1337)
        let encoded = try? JSONEncoder().encode(codable)
        XCTAssertNotNil(encoded)
    }
    
    func testEncodeDouble() {
        let codable = AnyCodable(13.37)
        let encoded = try? JSONEncoder().encode(codable)
        XCTAssertNotNil(encoded)
    }
    
    func testEncodeString() {
        let codable = AnyCodable("aString")
        let encoded = try? JSONEncoder().encode(codable)
        XCTAssertNotNil(encoded)
    }
    
    func testEncodeArray() {
        let codable = AnyCodable([1,1,1])
        let encoded = try? JSONEncoder().encode(codable)
        XCTAssertNotNil(encoded)
    }
    
//    func testEncodeStruct() {
//        let obj = TestStruct(test: 93)
//        let codable = AnyCodable(obj)
//        let encoded = try? JSONEncoder().encode(codable)
//        XCTAssertNotNil(encoded)
//    }
}

struct TestStruct: Codable, Equatable {
    let int: Int
}

public struct EthTransaction: Codable, Equatable {
    public let from: String
    public let data: String
    public let gasLimit: String
    public let value: String
    public let to: String
    public let gasPrice: String
    public let nonce: String
    
    static func make(_ nonce: String = "0x00") -> EthTransaction {
        EthTransaction(
            from: "0xdeadbeef", data: "some data",
            gasLimit: "0.001", value: "1.001",
            to: "0x02394854", gasPrice: "0.3", nonce: nonce)
    }
}
