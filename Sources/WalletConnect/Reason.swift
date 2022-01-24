// TODO: Refactor into codes. Reference: https://docs.walletconnect.com/2.0/protocol/reason-codes
public struct Reason {
    
    public let code: Int
    public let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}



enum ReasonCode {
    case generic(message: String)
    case invalidUpdateRequest(String)
    
    var code: Int {
        switch self {
        case .generic: return 0
        case .invalidUpdateRequest: return 1003
        }
    }
    
    var message: String {
        switch self {
        case .generic(let message): return message
        case .invalidUpdateRequest(let context): return "Invalid \(context) update request"
        }
    }
}

//code: 1301
//message: "No matching ${context} with topic: ${topic}"

//code: 3003
//message: "Unauthorized ${context} update request"

//code: 3005
//message: "Unauthorized: peer is also ${"" | "not"} controller"
