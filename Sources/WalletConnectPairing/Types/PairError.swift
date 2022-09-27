import WalletConnectNetworking

public enum PairError: Codable, Equatable, Error, Reason {
    case methodUnsupported

    public var code: Int {
        //TODO - spec code
        return 44444
    }

    //TODO - spec message
    public var message: String {
        return "Method Unsupported"
    }

}
