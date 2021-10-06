import XCTest
@testable import WalletConnect

struct CodableStub: Codable, Equatable {
    let bool: Bool
    let int: Int
    let double: Double
    let string: String
    let object: Obje
    
    struct Obje: Codable, Equatable {
        let string: String
    }
    
    static func stub() -> CodableStub {
        CodableStub(
            bool: Bool.random(),
            int: Int.random(in: Int.min...Int.max),
            double: Double.random(in: -1337.00...1337.00),
            string: UUID().uuidString,
            object: Obje(string: UUID().uuidString)
        )
    }
}

class AnyCodableTests: XCTestCase {

    func testCodingBool() {
        [true, false].forEach { bool in
            do {
                let anyCodable = AnyCodable(bool)
                let encoded = try JSONEncoder().encode(anyCodable)
                let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
                let codingResult = decoded.get(Bool.self)
                XCTAssertEqual(bool, codingResult)
            } catch {
                XCTFail()
            }
        }
    }
    
    func testCodingInt() {
        do {
            let int = Int.random(in: Int.min...Int.max)
            let anyCodable = AnyCodable(int)
            let encoded = try JSONEncoder().encode(anyCodable)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            let codingResult = decoded.get(Int.self)
            XCTAssertEqual(int, codingResult)
        } catch {
            XCTFail()
        }
    }
    
    func testCodingDouble() {
        do {
            let double = Double.random(in: -1337.00...1337.00)
            let anyCodable = AnyCodable(double)
            let encoded = try JSONEncoder().encode(anyCodable)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            let codingResult = decoded.get(Double.self)
            XCTAssertEqual(double, codingResult)
        } catch {
            XCTFail()
        }
    }
    
    func testCodingString() {
        do {
            let string = UUID().uuidString
            let anyCodable = AnyCodable(string)
            let encoded = try JSONEncoder().encode(anyCodable)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            let codingResult = decoded.get(String.self)
            XCTAssertEqual(string, codingResult)
        } catch {
            XCTFail()
        }
    }
    
    func testCodingArray() {
        do {
            let array = (1...10).map { _ in UUID().uuidString }
            let anyCodable = AnyCodable(array)
            let encoded = try JSONEncoder().encode(anyCodable)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            let codingResult = decoded.get([String].self)
            XCTAssertEqual(array, codingResult)
        } catch {
            XCTFail()
        }
    }
    
    func testCodingStruct() {
        do {
            let object = CodableStub.stub()
            let value = AnyCodable(object)
            let encoded = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            let codingResult = decoded.get(CodableStub.self)
            XCTAssertEqual(object, codingResult)
        } catch {
            XCTFail()
        }
    }
    
    func testCodingStructArray() {
        do {
            let objects = (1...10).map { _ in CodableStub.stub() }
            let value = AnyCodable(objects)
            let encoded = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            let codingResult = decoded.get([CodableStub].self)
            XCTAssertEqual(objects, codingResult)
        } catch {
            XCTFail()
        }
    }
}
