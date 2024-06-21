
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

class Account {
    static var instance: AccountClientMock = {
        fatalError("Error - you must call Account.initialize(entryPoint:chainId:) before accessing the shared instance.")
    }()

    private init() {}

    static func initialize(entryPoint: String, chainId: Int) {
        instance = AccountClientMock(entryPoint: entryPoint, chainId: chainId, onSign: nil)
    }

    static func setOnSign(_ onSign: @escaping OnSign) {
        instance.onSign = onSign
    }
}
