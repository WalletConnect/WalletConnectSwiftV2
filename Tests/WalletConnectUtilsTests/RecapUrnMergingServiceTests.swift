import XCTest
@testable import WalletConnectUtils

class RecapUrnMergingTests: XCTestCase {
    func testMergeRecapUrns() throws {
        // Encode your test data to Base64
        let notifyRecapJson = """
        {
           "att":{
              "https://notify.walletconnect.com/all-apps":{
                 "crud/notifications": [{}],
                 "crud/subscriptions": [{}]
              }
           }
        }
        """
        let signRecapJson = """
        {
           "att":{
              "eip155":{
                 "request/eth_sendTransaction": [{}],
                 "request/personal_sign": [{}]
              }
           }
        }
        """

        guard let notifyBase64 = notifyRecapJson.data(using: .utf8)?.base64urlEncodedString(),
              let signBase64 = signRecapJson.data(using: .utf8)?.base64urlEncodedString() else {
            XCTFail("Failed to encode JSON strings to Base64")
            return
        }

        // Create URNs from Base64 encoded strings
        let urn1 = try RecapUrn(urn: "urn:recap:\(notifyBase64)")
        let urn2 = try RecapUrn(urn: "urn:recap:\(signBase64)")

        // Merge the URNs using your merging logic
        let mergedRecap = try RecapUrnMergingService.merge(recapUrns: [urn1, urn2])

        // Define the expected merged structure
        let expectedMergeJson = """
        {
           "att":{
              "https://notify.walletconnect.com/all-apps":{
                 "crud/notifications": [{}],
                 "crud/subscriptions": [{}]
              },
              "eip155":{
                 "request/eth_sendTransaction": [{}],
                 "request/personal_sign": [{}]
              }
           }
        }
        """

        // Convert expected JSON to `RecapData`
        let expectedMergeData = expectedMergeJson.data(using: .utf8)!
        let expectedMergeRecap = try! JSONDecoder().decode(RecapData.self, from: expectedMergeData)

        // Perform your assertions
        XCTAssertEqual(mergedRecap.recapData.att?.count, expectedMergeRecap.att?.count)
        for (key, value) in mergedRecap.recapData.att ?? [:] {
            XCTAssertEqual(value.keys.sorted(), expectedMergeRecap.att?[key]?.keys.sorted())
        }
    }
}
