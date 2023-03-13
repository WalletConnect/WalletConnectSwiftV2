import Foundation
import XCTest
@testable import WalletConnectSigner

class ENSSignerTests: XCTestCase {

    private let account = Account("eip155:1:0x025d1eAC1467c5be5e38cA411dC2454964B5C666")!

    func testResolveAddress() async throws {
        let resolver = ENSResolverFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        let ens = try await resolver.resolve(account: account)
        XCTAssertEqual(ens, "web3.eth")
    }
}
