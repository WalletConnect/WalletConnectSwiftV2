import XCTest
@testable import WalletConnectKMS

final class EnvelopeTests: XCTestCase {

    func testSerialisation() {
        let pubKey = Data(hex: "f82388e76d53632d8c73e4f4dbfe122321affee5d79cb63ee804a4ef251f4219")
        let sealbox = Data(base64Encoded: "V2FsbGV0Q29ubmVjdA==")!
        let envelope = Envelope(type: .type1(pubKey: pubKey), sealbox: sealbox, codingType: .base64Encoded)
        let serialised = envelope.serialised(codingType: .base64Encoded)
        let deserialised = try! Envelope(.base64Encoded, envelopeString: serialised)
        XCTAssertEqual(envelope, deserialised)
    }

    func testDeserialise() {
        let serialised = "AnsibWV0aG9kIjoid2Nfc2Vzc2lvbkF1dGhlbnRpY2F0ZSIsImlkIjoxNzEyMjIwNjg1NjM1MzAzLCJqc29ucnBjIjoiMi4wIiwicGFyYW1zIjp7ImV4cGlyeVRpbWVzdGFtcCI6MTcxMjIyNDI4NSwiYXV0aFBheWxvYWQiOnsidHlwZSI6ImVpcDQzNjEiLCJzdGF0ZW1lbnQiOiJJIGFjY2VwdCB0aGUgU2VydmljZU9yZyBUZXJtcyBvZiBTZXJ2aWNlOiBodHRwczpcL1wvYXBwLndlYjNpbmJveC5jb21cL3RvcyIsImNoYWlucyI6WyJlaXAxNTU6MSIsImVpcDE1NToxMzciXSwicmVzb3VyY2VzIjpbInVybjpyZWNhcDpleUpoZEhRaU9uc2laV2x3TVRVMUlqcDdJbkpsY1hWbGMzUXZjR1Z5YzI5dVlXeGZjMmxuYmlJNlczdDlYWDE5ZlE9PSJdLCJkb21haW4iOiJhcHAud2ViM2luYm94IiwidmVyc2lvbiI6IjEiLCJhdWQiOiJodHRwczpcL1wvYXBwLndlYjNpbmJveC5jb21cL2xvZ2luIiwibm9uY2UiOiIzMjg5MTc1NiIsImlhdCI6IjIwMjQtMDQtMDRUMDg6NTE6MjVaIn0sInJlcXVlc3RlciI6eyJwdWJsaWNLZXkiOiIxOWYzNmY1N2M1NjYxNDY4ODk0NmU3MzliNzY4NmE2ZmE1OGNiZWFmOGQ3MzZmM2EzZDI2NjVlM2NlYmE4ZDQ5IiwibWV0YWRhdGEiOnsicmVkaXJlY3QiOnsibmF0aXZlIjoid2NkYXBwOlwvXC8iLCJ1bml2ZXJzYWwiOiJ3d3cud2FsbGV0Y29ubmVjdC5jb21cL2RhcHAifSwiaWNvbnMiOlsiaHR0cHM6XC9cL2F2YXRhcnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tXC91XC8zNzc4NDg4NiJdLCJkZXNjcmlwdGlvbiI6IldhbGxldENvbm5lY3QgREFwcCBzYW1wbGUiLCJ1cmwiOiJ3YWxsZXQuY29ubmVjdCIsIm5hbWUiOiJTd2lmdCBEYXBwIn19fX0"

        let deserialised = try! Envelope(.base64UrlEncoded, envelopeString: serialised)
        XCTAssertEqual(deserialised.type, .type2)
    }

    func testInitWithValidBase64EncodedType0() {
        let envelopeString = "AFdhbGxldENvbm5lY3Q="
        let envelope = try? Envelope(.base64Encoded, envelopeString: envelopeString)

        XCTAssertNotNil(envelope)
        XCTAssertEqual(envelope?.type, .type0)
        XCTAssertEqual(envelope?.sealbox, Data(base64Encoded: "V2FsbGV0Q29ubmVjdA=="))
    }

    func testInitWithInvalidBase64() {
        XCTAssertThrowsError(try Envelope(.base64Encoded, envelopeString: "invalid_base64")) { error in
            XCTAssertEqual(error as? Envelope.Errors, .malformedEnvelope)
        }
    }

    func testInitWithInvalidBase64Url() {
        XCTAssertThrowsError(try Envelope(.base64UrlEncoded, envelopeString: "invalid_base64url")) { error in
            XCTAssertEqual(error as? Envelope.Errors, .malformedEnvelope)
        }
    }

    func testInitWithValidType1Envelope() {
        let pubKeyHex = "f82388e76d53632d8c73e4f4dbfe122321affee5d79cb63ee804a4ef251f4219"
        let sealboxBase64 = "V2FsbGV0Q29ubmVjdA=="
        let pubKey = Data(hex: pubKeyHex)
        let sealbox = Data(base64Encoded: sealboxBase64)!

        // Create the Envelope object
        let envelope = Envelope(type: .type1(pubKey: pubKey), sealbox: sealbox, codingType: .base64Encoded)

        // Serialize the Envelope object
        let serializedEnvelopeString = envelope.serialised(codingType: .base64Encoded)

        // Deserialize the serialized string to create a new Envelope object
        let deserializedEnvelope = try? Envelope(.base64Encoded, envelopeString: serializedEnvelopeString)

        // Ensure the deserialized envelope is not nil
        XCTAssertNotNil(deserializedEnvelope)
        guard let deserializedEnvelope = deserializedEnvelope else {
            XCTFail("Deserialized envelope is nil")
            return
        }

        // Verify the deserialized envelope type and public key
        if case let .type1(actualPubKey) = deserializedEnvelope.type {
            XCTAssertEqual(actualPubKey, pubKey, "Public keys do not match")
        } else {
            XCTFail("Envelope type is not type1")
        }

        // Verify the sealbox of the deserialized envelope
        XCTAssertEqual(deserializedEnvelope.sealbox, sealbox, "Sealbox data does not match")
    }

    func testInitWithValidBase64UrlEncodedType2() {
        let jsonString = "{\"key\":\"value\"}"
        let envelope = Envelope(type: .type2, sealbox: Data(jsonString.utf8), codingType: .base64UrlEncoded)
        let serializedEnvelopeString = envelope.serialised(codingType: .base64UrlEncoded)

        let deserializedEnvelope = try? Envelope(.base64UrlEncoded, envelopeString: serializedEnvelopeString)

        XCTAssertNotNil(deserializedEnvelope)
        guard let deserializedEnvelope = deserializedEnvelope else {
            XCTFail("Deserialized envelope is nil")
            return
        }

        XCTAssertEqual(deserializedEnvelope.type, .type2)
        XCTAssertEqual(deserializedEnvelope.sealbox, Data(jsonString.utf8))
    }

    func testInitWithValidBase64EncodedType0_CustomData() {
        let customData = "TestCustomData".data(using: .utf8)!
        let envelope = Envelope(type: .type0, sealbox: customData, codingType: .base64Encoded)
        let serializedEnvelopeString = envelope.serialised(codingType: .base64Encoded)

        let deserializedEnvelope = try? Envelope(.base64Encoded, envelopeString: serializedEnvelopeString)

        XCTAssertNotNil(deserializedEnvelope)
        guard let deserializedEnvelope = deserializedEnvelope else {
            XCTFail("Deserialized envelope is nil")
            return
        }

        XCTAssertEqual(deserializedEnvelope.type, .type0)
        XCTAssertEqual(deserializedEnvelope.sealbox, customData)
    }

    // Envelope type tests

    func testEnvelopeTypeInitWithType0() {
            let envelopeType = try? Envelope.EnvelopeType(representingByte: 0, pubKey: nil)
            XCTAssertNotNil(envelopeType)
            XCTAssertEqual(envelopeType, .type0)
        }

        func testEnvelopeTypeInitWithType1ValidPubKey() {
            let pubKey = Data(hex: "f82388e76d53632d8c73e4f4dbfe122321affee5d79cb63ee804a4ef251f4219")
            let envelopeType = try? Envelope.EnvelopeType(representingByte: 1, pubKey: pubKey)
            XCTAssertNotNil(envelopeType)
            XCTAssertEqual(envelopeType, .type1(pubKey: pubKey))
        }

        func testEnvelopeTypeInitWithType1InvalidPubKey() {
            let invalidPubKey = Data(hex: "f82388e76d53632d8c73e4f4dbfe122321af") // Shorter than 32 bytes
            XCTAssertThrowsError(try Envelope.EnvelopeType(representingByte: 1, pubKey: invalidPubKey)) { error in
                XCTAssertEqual(error as? Envelope.Errors, .malformedEnvelope)
            }
        }

        func testEnvelopeTypeInitWithType1NilPubKey() {
            XCTAssertThrowsError(try Envelope.EnvelopeType(representingByte: 1, pubKey: nil)) { error in
                XCTAssertEqual(error as? Envelope.Errors, .malformedEnvelope)
            }
        }

        func testEnvelopeTypeInitWithType2() {
            let envelopeType = try? Envelope.EnvelopeType(representingByte: 2, pubKey: nil)
            XCTAssertNotNil(envelopeType)
            XCTAssertEqual(envelopeType, .type2)
        }

        func testEnvelopeTypeInitWithUnsupportedType() {
            XCTAssertThrowsError(try Envelope.EnvelopeType(representingByte: 3, pubKey: nil)) { error in
                XCTAssertEqual(error as? Envelope.Errors, .unsupportedEnvelopeType)
            }
        }
}

