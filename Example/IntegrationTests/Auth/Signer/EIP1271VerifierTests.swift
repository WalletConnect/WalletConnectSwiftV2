import Foundation
import XCTest
@testable import Auth
@testable import WalletConnectSigner
import JSONRPC

class EIP1271VerifierTests: XCTestCase {

    let signature = Data(hex: "c1505719b2504095116db01baaf276361efd3a73c28cf8cc28dabefa945b8d536011289ac0a3b048600c1e692ff173ca944246cf7ceb319ac2262d27b395c82b1c")

    let message = Data(hex: "19457468657265756d205369676e6564204d6573736167653a0a3235326c6f63616c686f73742077616e747320796f7520746f207369676e20696e207769746820796f757220457468657265756d206163636f756e743a0a3078326661663833633534326236386631623463646330653737306538636239663536376230386637310a0a5552493a20687474703a2f2f6c6f63616c686f73743a333030302f0a56657273696f6e3a20310a436861696e2049443a20310a4e6f6e63653a20313636353434333031353730300a4973737565642041743a20323032322d31302d31305432333a30333a33352e3730305a0a45787069726174696f6e2054696d653a20323032322d31302d31315432333a30333a33352e3730305a")

    let address = "0x2faf83c542b68f1b4cdc0e770e8cb9f567b08f71"
    let chainId = "eip155:1"

    func testSuccessVerify() async throws {
        let httpClient = HTTPNetworkClient(host: "rpc.walletconnect.com")
        let signer = DefaultSignerFactory().createEthereumSigner()
        let verifier = EIP1271Verifier(projectId: InputConfig.projectId, httpClient: httpClient, signer: signer)
        try await verifier.verify(
            signature: signature,
            message: message,
            address: address,
            chainId: chainId
        )
    }

    func testFailureVerify() async throws {
        let httpClient = HTTPNetworkClient(host: "rpc.walletconnect.com")
        let signer = DefaultSignerFactory().createEthereumSigner()
        let verifier = EIP1271Verifier(projectId: InputConfig.projectId, httpClient: httpClient, signer: signer)

        await XCTAssertThrowsErrorAsync(try await verifier.verify(
            signature: Data("deadbeaf"),
            message: message,
            address: address,
            chainId: chainId
        ))
    }
}
