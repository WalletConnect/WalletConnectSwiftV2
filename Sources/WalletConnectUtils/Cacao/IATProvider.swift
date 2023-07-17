import Foundation

public protocol IATProvider {
    var iat: String { get }
}

public struct DefaultIATProvider: IATProvider {

    public init() { }

    public var iat: String {
        return ISO8601DateFormatter().string(from: Date())
    }
}

#if DEBUG
struct IATProviderMock: IATProvider {
    var iat: String {
        return "2022-10-10T23:03:35.700Z"
    }
}
#endif
