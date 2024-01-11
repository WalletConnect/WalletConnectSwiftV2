import XCTest
@testable import WalletConnectSign

class SessionProposalTests: XCTestCase {

    func testProposalNotExpiredImmediately() {
        let proposal = SessionProposal.stub()
        XCTAssertFalse(proposal.isExpired(), "Proposal should not be expired immediately after creation.")
    }

    func testProposalExpired() {
        let proposal = SessionProposal.stub()
        let expiredDate = Date(timeIntervalSince1970: TimeInterval(proposal.expiry! + 1))
        XCTAssertTrue(proposal.isExpired(currentDate: expiredDate), "Proposal should be expired after the expiry time.")
    }

    func testProposalNotExpiredJustBeforeExpiry() {
        let proposal = SessionProposal.stub()
        let justBeforeExpiryDate = Date(timeIntervalSince1970: TimeInterval(proposal.expiry! - 1))
        XCTAssertFalse(proposal.isExpired(currentDate: justBeforeExpiryDate), "Proposal should not be expired just before the expiry time.")
    }
}
