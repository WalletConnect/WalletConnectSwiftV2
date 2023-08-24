import Foundation
import XCTest
@testable import WalletConnectSigner

class ENSResolverTests: XCTestCase {

    private let account = Account("eip155:1:0xD02D090F8f99B61D65d8e8876Ea86c2720aB27BC")!
    private let ens = "web3.eth"

    // Note: - removed until RPC server fix
    //    func testResolveEns() async throws {
    //        let resolver = ENSResolverFactory(crypto: DefaultCryptoProvider()).create(projectId: InputConfig.projectId)
    //        let resolved = try await resolver.resolveEns(account: account)
    //        XCTAssertEqual(resolved, ens)
    //    }
    //
    //    func testResolveAddress() async throws {
    //        let resolver = ENSResolverFactory(crypto: DefaultCryptoProvider()).create(projectId: InputConfig.projectId)
    //        let resolved = try await resolver.resolveAddress(ens: ens, blockchain: account.blockchain)
    //        XCTAssertEqual(resolved, account)
    //    }
}
