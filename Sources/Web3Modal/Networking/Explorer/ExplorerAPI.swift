import Foundation
import HTTPClient

enum ExplorerAPI: HTTPService {
    case getListings(projectId: String, metadata: AppMetadata)

    var path: String {
        switch self {
        case .getListings: return "/w3m/v1/getiOSListings"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getListings: return .get
        }
    }

    var body: Data? {
        nil
    }

    var queryParameters: [String: String]? {
        switch self {
        case let .getListings(projectId, _):
            return [
                "projectId": projectId,
                "page": "1",
                "entries": "300",
            ]
        }
    }

    var scheme: String {
        return "https"
    }

    var additionalHeaderFields: [String: String]? {
        
        switch self {
        case let .getListings(_, metadata):
            return [
                "User-Agent": ExplorerAPI.userAgent,
                "referer": metadata.name
            ]
        }
    }
    
    private static var protocolName: String {
        "w3m-ios-1.0.0"
    }
    
    static var userAgent: String {
        "\(protocolName)/\(EnvironmentInfo.sdkName)/\(EnvironmentInfo.operatingSystem)"
    }
}
