
public enum PairError: Codable, Equatable, Error, Reason {
    case methodUnsupported

    public init?(code: Int) {
        switch code {
        case Self.methodUnsupported.code:
            self = .methodUnsupported
        default:
            return nil
        }
    }

    public var code: Int {
        switch self {
        case .methodUnsupported:
            return 10001
        }
    }

    public var message: String {
        return "Method Unsupported"
    }

}
