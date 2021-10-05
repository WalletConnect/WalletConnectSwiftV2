
import Foundation

public struct EthereumJsonrpcRequestsHandler {
    public static func handle(request: JSONRPCRequest<AnyCodable>) -> EthereumJsonrpcParams? {
        if request.method == "eth_sendTransaction" {
            if let ethSendTransactionRequestDictArray = request.params.value as? [[String: String]],
               let ethSendTransactionRequestDict = ethSendTransactionRequestDictArray.first,
               let from = ethSendTransactionRequestDict["from"],
               let data = ethSendTransactionRequestDict["data"],
               let gasLimit = ethSendTransactionRequestDict["gasLimit"],
               let value = ethSendTransactionRequestDict["value"],
               let to = ethSendTransactionRequestDict["to"],
               let gasPrice = ethSendTransactionRequestDict["gasPrice"],
               let nonce = ethSendTransactionRequestDict["nonce"] {
                let ethSendTransaction = EthSendTransaction(from: from, data: data, gasLimit: gasLimit, value: value, to: to, gasPrice: gasPrice, nonce: nonce)
                return .ethSendTransaction(ethSendTransaction)
            }
        }
        return nil
    }
}
