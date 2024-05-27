import XCTest
@testable import WalletConnectKMS

final class EnvelopeTests: XCTestCase {
    let pubKey = Data(hex: "f82388e76d53632d8c73e4f4dbfe122321affee5d79cb63ee804a4ef251f4219")
    let sealbox = Data(base64Encoded: "V2FsbGV0Q29ubmVjdA==")!

    func testSerialisation() {
        let envelope = Envelope(type: .type1(pubKey: pubKey), sealbox: sealbox, codingType: .base64Encoded)
        let serialised = envelope.serialised()
        let deserialised = try! Envelope(.base64Encoded, envelopeString: serialised)
        XCTAssertEqual(envelope, deserialised)
    }

    func testDeserialise() {
        let serialised = "AnsibWV0aG9kIjoid2Nfc2Vzc2lvbkF1dGhlbnRpY2F0ZSIsImlkIjoxNzEyMjIwNjg1NjM1MzAzLCJqc29ucnBjIjoiMi4wIiwicGFyYW1zIjp7ImV4cGlyeVRpbWVzdGFtcCI6MTcxMjIyNDI4NSwiYXV0aFBheWxvYWQiOnsidHlwZSI6ImVpcDQzNjEiLCJzdGF0ZW1lbnQiOiJJIGFjY2VwdCB0aGUgU2VydmljZU9yZyBUZXJtcyBvZiBTZXJ2aWNlOiBodHRwczpcL1wvYXBwLndlYjNpbmJveC5jb21cL3RvcyIsImNoYWlucyI6WyJlaXAxNTU6MSIsImVpcDE1NToxMzciXSwicmVzb3VyY2VzIjpbInVybjpyZWNhcDpleUpoZEhRaU9uc2laV2x3TVRVMUlqcDdJbkpsY1hWbGMzUXZjR1Z5YzI5dVlXeGZjMmxuYmlJNlczdDlYWDE5ZlE9PSJdLCJkb21haW4iOiJhcHAud2ViM2luYm94IiwidmVyc2lvbiI6IjEiLCJhdWQiOiJodHRwczpcL1wvYXBwLndlYjNpbmJveC5jb21cL2xvZ2luIiwibm9uY2UiOiIzMjg5MTc1NiIsImlhdCI6IjIwMjQtMDQtMDRUMDg6NTE6MjVaIn0sInJlcXVlc3RlciI6eyJwdWJsaWNLZXkiOiIxOWYzNmY1N2M1NjYxNDY4ODk0NmU3MzliNzY4NmE2ZmE1OGNiZWFmOGQ3MzZmM2EzZDI2NjVlM2NlYmE4ZDQ5IiwibWV0YWRhdGEiOnsicmVkaXJlY3QiOnsibmF0aXZlIjoid2NkYXBwOlwvXC8iLCJ1bml2ZXJzYWwiOiJ3d3cud2FsbGV0Y29ubmVjdC5jb21cL2RhcHAifSwiaWNvbnMiOlsiaHR0cHM6XC9cL2F2YXRhcnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tXC91XC8zNzc4NDg4NiJdLCJkZXNjcmlwdGlvbiI6IldhbGxldENvbm5lY3QgREFwcCBzYW1wbGUiLCJ1cmwiOiJ3YWxsZXQuY29ubmVjdCIsIm5hbWUiOiJTd2lmdCBEYXBwIn19fX0"

        let deserialised = try! Envelope(.base64UrlEncoded, envelopeString: serialised)
        XCTAssertEqual(deserialised.type, .type2)
    }

}
