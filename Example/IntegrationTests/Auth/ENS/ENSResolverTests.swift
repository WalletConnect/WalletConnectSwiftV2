import Foundation
import XCTest
@testable import WalletConnectSigner

class ENSSignerTests: XCTestCase {

    private let account = Account("eip155:1:0x025d1eac1467c5be5e38ca411dc2454964b5c666")!
    private let ens = "web3.eth"

    func testResolveEns() async throws {
        let resolver = ENSResolverFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        let resolved = try await resolver.resolveEns(account: account)
        XCTAssertEqual(resolved, ens)
    }

    func testResolveAddress() async throws {
        let resolver = ENSResolverFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        let address = try await resolver.resolveAddress(ens: ens, blockchain: account.blockchain)
        XCTAssertEqual(address, account.address)
    }
}
