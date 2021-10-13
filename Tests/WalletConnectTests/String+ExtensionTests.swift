import XCTest
@testable import WalletConnect

final class StringExtensionTests: XCTestCase {
    
    func testGenericPasswordConvertible() {
        let string = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let restoredString = try? String(rawRepresentation: string.rawRepresentation)
        XCTAssertEqual(string, restoredString)
    }
}
