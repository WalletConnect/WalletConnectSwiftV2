
import Foundation
import WalletConnectAccount
import WalletConnectUtils

class AccountClientMock: AccountClientProtocol {
    var onSign: WalletConnectAccount.OnSign?
    
    var chainId: Int

    required init(entryPoint: String, chainId: Int, onSign: WalletConnectAccount.OnSign?) {
        self.chainId = chainId
        self.onSign = onSign
    }

    // prepares UserOp
    func sendTransaction(_ transaction: WalletConnectAccount.Transaction) async throws -> String {
        return "userOpHash"
    }
    
    func sendBatchTransaction(_ batch: [WalletConnectAccount.Transaction]) async throws -> String {
        return "receipt"
    }
    
    func getAddress() -> String {
        return "0x123"
    }
    
    func signMessage(_ message: String) -> String {
        guard let onSign = onSign else {
            fatalError("Error - onSign closure must be set before calling signMessage")
        }
        return onSign(message)
    }
}

class SmartAccount {
    static var instance: AccountClientMock = {
        guard let config = SmartAccount.config else {
            fatalError("Error - you must call SmartAccount.configure(entryPoint:chainId:onSign:) before accessing the shared instance.")
        }
        return AccountClientMock(entryPoint: config.entryPoint, chainId: config.chainId, onSign: config.onSign)
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
    static public func configure(entryPoint: String, chainId: Int, onSign: OnSign? = nil) {
        SmartAccount.config = Config(entryPoint: entryPoint, chainId: chainId, onSign: onSign)
    }

    static func setOnSign(_ onSign: @escaping OnSign) {
        instance.onSign = onSign
    }
}
