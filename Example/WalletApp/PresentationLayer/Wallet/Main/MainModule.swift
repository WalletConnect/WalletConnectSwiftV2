import SwiftUI
import Web3
import YttriumWrapper

let mnemonic = "test test test test test test test test test test test junk"

final class MainModule {
    @discardableResult
    static func create(app: Application, importAccount: ImportAccount) -> UIViewController {
        let router = MainRouter(app: app)
        let interactor = MainInteractor()
        let presenter = MainPresenter(router: router, interactor: interactor, importAccount: importAccount, pushRegisterer: app.pushRegisterer, configurationService: app.configurationService)
        let viewController = MainViewController(presenter: presenter)

        configureSmartAccountOnSign(importAccount: importAccount)
        router.viewController = viewController

        return viewController
    }

    static func configureSmartAccountOnSign(importAccount: ImportAccount) {
        let privateKey = importAccount.privateKey
        let ownerAddress = String(importAccount.account.address.dropFirst(2))
        SmartAccount.instance.register(
            owner: ownerAddress,
            privateKey: privateKey
        )
//        SmartAccount.instance.register(onSign: { (messageToSign: String) in
//            func dataToHash(_ data: Data) -> Bytes {
//                let prefix = "\u{19}Ethereum Signed Message:\n"
//                let prefixData = (prefix + String(data.count)).data(using: .utf8)!
//                let prefixedMessageData = prefixData + data
//                return .init(hex: prefixedMessageData.toHexString())
//            }
//
//            let prvKey = try! EthereumPrivateKey(hexPrivateKey: importAccount.privateKey)
//
//            // Determine if the message is hex-encoded or plain text
//            let dataToSign: Bytes
//            if messageToSign.hasPrefix("0x") {
//                // Hex-encoded message, remove "0x" and convert
//                let messageData = Data(hex: String(messageToSign.dropFirst(2)))
//                dataToSign = dataToHash(messageData)
//            } else {
//                // Plain text message, convert directly to data
//                let messageData = Data(messageToSign.utf8)
//                dataToSign = dataToHash(messageData)
//            }
//
//            // Sign the data
//            let (v, r, s) = try! prvKey.sign(message: .init(Data(dataToSign)))
//            let result = "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16)
//            return .success(result)
//        })
    }
}
