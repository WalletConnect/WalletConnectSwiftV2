import XCTest
@testable import WalletConnectKMS

final class EnvelopeTests: XCTestCase {
    let pubKey = Data(hex: "f82388e76d53632d8c73e4f4dbfe122321affee5d79cb63ee804a4ef251f4219")
    let sealbox = Data(base64Encoded: "V2FsbGV0Q29ubmVjdA==")!

    func testSerialisation() {
        let envelope = Envelope(type: .type1(pubKey: pubKey), sealbox: sealbox)
        let serialised = envelope.serialised()
        let deserialised = try! Envelope(serialised)
        XCTAssertEqual(envelope, deserialised)
    }

}
