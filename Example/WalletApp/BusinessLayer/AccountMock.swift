import Foundation
import YttriumWrapper
import WalletConnectUtils

class AccountClientMock: YttriumWrapper.AccountClientProtocol {
    
    var onSign: OnSign?
    
    var chainId: Int

    required init(entryPoint: String, chainId: Int, onSign: OnSign?) {
        self.chainId = chainId
        self.onSign = onSign
    }

    // prepares UserOp
    func sendTransaction(_ transaction: YttriumWrapper.Transaction) async throws -> String {
        guard let onSign = onSign else {
            fatalError("Error - onSign closure must be set before calling signMessage")
        }
        let _ = onSign("UserOp")
        return "txHash"
    }
    
    func sendBatchTransaction(_ batch: [YttriumWrapper.Transaction]) async throws -> String {
        return "userOpReceipt"
    }
    
    func getAddress() async throws -> String {
        return "0xF4D7560648F1252FD7501863355AEaBfb9d3b7c3"
    }

    func getAccount() async throws -> Account {
        let chain = try Blockchain(namespace: "eip155", reference: chainId)
        let address = try await getAddress()
        return try Account(blockchain: chain, accountAddress: address)
    }

    func signMessage(_ message: String) throws -> String {
        guard let onSign = onSign else {
            fatalError("Error - onSign closure must be set before calling signMessage")
        }
        return try! onSign(message).get()
    }
}

extension YttriumWrapper.AccountClient {
    
    func getAccount() async throws -> Account {
        let chain = try Blockchain(namespace: "eip155", reference: chainId)
        let address = try await getAddress()
        return try Account(blockchain: chain, accountAddress: address)
    }
}

class SmartAccount {
    static var mockInstance: AccountClientMock = {
        guard let config = SmartAccount.config else {
            fatalError("Error - you must call SmartAccount.configure(entryPoint:chainId:onSign:) before accessing the shared instance.")
        }
        return AccountClientMock(
            entryPoint: config.entryPoint,
            chainId: config.chainId,
            onSign: config.onSign
        )
    }()
    
    static var instance: AccountClient = {
        guard let config = SmartAccount.config else {
            fatalError("Error - you must call SmartAccount.configure(entryPoint:chainId:onSign:) before accessing the shared instance.")
        }
        return AccountClient(
            entryPoint: config.entryPoint,
            chainId: config.chainId,
            onSign: config.onSign
        )
    }()

    private static var config: Config?

    private init() {}

    struct Config {
        let entryPoint: String
        let chainId: Int
        var onSign: OnSign?
    }

    /// SmartAccount instance config method
    /// - Parameters:
    ///   - entryPoint: Entry point
    ///   - chainId: Chain ID
    ///   - onSign: Closure for signing messages (optional)
    static public func configure(
        entryPoint: String,
        chainId: Int,
        onSign: OnSign? = nil
    ) {
        SmartAccount.config = Config(entryPoint: entryPoint, chainId: chainId, onSign: onSign)
    }
}
