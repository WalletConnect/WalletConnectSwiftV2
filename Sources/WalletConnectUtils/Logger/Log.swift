import Foundation

public struct LogMessage {

    public let message: String
    public let properties: [String: String]?

    public var aggregated: String {
        var aggregatedProperties = ""

        properties?.forEach { key, value in
            aggregatedProperties += "\(key): \(value), "
        }

        if !aggregatedProperties.isEmpty {
            aggregatedProperties = String(aggregatedProperties.dropLast(2))
        }

        return "\(message), properties: [\(aggregatedProperties)]"
    }

    public init(message: String, properties: [String : String]? = nil) {
        self.message = message
        self.properties = properties
    }
}

public enum Log {
    case error(LogMessage)
    case warn(LogMessage)
    case info(LogMessage)
    case debug(LogMessage)
}
