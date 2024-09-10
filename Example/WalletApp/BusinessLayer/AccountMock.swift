import Foundation
import YttriumWrapper
import WalletConnectUtils

class AccountClientMock: YttriumWrapper.AccountClientProtocol {
    
    var onSign: OnSign?
    
    var chainId: Int
    
    var ownerAddress: String
    
    var entryPoint: String
    
    private var config: Yttrium.Config
    
    required init(ownerAddress: String, entryPoint: String, chainId: Int, config: Yttrium.Config) {
        self.ownerAddress = ownerAddress
        self.entryPoint = entryPoint
        self.chainId = chainId
        self.config = config
    }
    
    func register(privateKey: String) {
        
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
    
    static var instance = SmartAccount()
    
    private var client: AccountClient? {
        didSet {
            if let _ = client {
                clientSetContinuation?.resume()
            }
        }
    }
    
    private var clientSetContinuation: CheckedContinuation<Void, Never>?
    
    private var config: Config?

    private init() {}
    
    public func configure(entryPoint: String, chainId: Int) {
        self.config = Config(
            entryPoint: entryPoint,
            chainId: chainId
        )
    }
    
    public func register(owner: String, privateKey: String) {
        guard let config = self.config else {
            fatalError("Error - you must call SmartAccount.configure(entryPoint:chainId:onSign:) before accessing the shared instance.")
        }
        assert(owner.count == 40)
        let client = AccountClient(
            ownerAddress: owner,
            entryPoint: config.entryPoint,
            chainId: config.chainId,
            config: .local()
        )
        client.register(privateKey: privateKey)
        
        self.client = client
    }


    public func getClient() async -> AccountClient {
        if let client = client {
            return client
        }

        await withCheckedContinuation { continuation in
            self.clientSetContinuation = continuation
        }
        
        return client!
    }

    struct Config {
        let entryPoint: String
        let chainId: Int
    }
}
