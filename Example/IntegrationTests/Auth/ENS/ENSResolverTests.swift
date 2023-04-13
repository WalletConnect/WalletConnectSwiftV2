import Foundation
import XCTest
@testable import WalletConnectSigner

class ENSResolverTests: XCTestCase {

    private let account = Account("eip155:1:0xd02d090f8f99b61d65d8e8876ea86c2720ab27bc")!
    private let ens = "web3.eth"

    func testResolveEns() async throws {
        let resolver = ENSResolverFactory(crypto: DefaultCryptoProvider()).create(projectId: InputConfig.projectId)
        let resolved = try await resolver.resolveEns(account: account)
        XCTAssertEqual(resolved, ens)
    }

    func testResolveAddress() async throws {
        let resolver = ENSResolverFactory(crypto: DefaultCryptoProvider()).create(projectId: InputConfig.projectId)
        let resolved = try await resolver.resolveAddress(ens: ens, blockchain: account.blockchain)
        XCTAssertEqual(resolved, account)
    }
}
