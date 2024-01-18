import XCTest
@testable import WalletConnectSign

class SessionProposalTests: XCTestCase {

    func testProposalNotExpiredImmediately() {
        let proposal = SessionProposal.stub()
        XCTAssertFalse(proposal.isExpired(), "Proposal should not be expired immediately after creation.")
    }

    func testProposalExpired() {
        let proposal = SessionProposal.stub()
        let expiredDate = Date(timeIntervalSince1970: TimeInterval(proposal.expiryTimestamp! + 1))
        XCTAssertTrue(proposal.isExpired(currentDate: expiredDate), "Proposal should be expired after the expiry time.")
    }

    func testProposalNotExpiredJustBeforeExpiry() {
        let proposal = SessionProposal.stub()
        let justBeforeExpiryDate = Date(timeIntervalSince1970: TimeInterval(proposal.expiryTimestamp! - 1))
        XCTAssertFalse(proposal.isExpired(currentDate: justBeforeExpiryDate), "Proposal should not be expired just before the expiry time.")
    }

    // for backward compatibility
    func testDecodingWithoutExpiry() throws {
        let json = """
        {
            "relays": [],
            "proposer": {
                "publicKey": "testKey",
                "metadata": {
                    "name": "Wallet Connect",
                    "description": "A protocol to connect blockchain wallets to dapps.",
                    "url": "https://walletconnect.com/",
                    "icons": []
                }
            },
            "requiredNamespaces": {},
            "optionalNamespaces": {},
            "sessionProperties": {}
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let proposal = try decoder.decode(SessionProposal.self, from: json)

        // Assertions
        XCTAssertNotNil(proposal, "Proposal should be successfully decoded even without an expiry field.")
        XCTAssertNil(proposal.expiryTimestamp, "Expiry should be nil if not provided in JSON.")
    }
}
