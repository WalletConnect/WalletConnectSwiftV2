import Foundation
import HTTPClient

enum ExplorerAPI: HTTPService {
    case getListings(
        projectId: String,
        metadata: AppMetadata,
        recommendedIds: [String],
        excludedIds: [String]
    )

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
        case let .getListings(projectId, _, recommendedIds, excludedIds):
            return [
                "projectId": projectId,
                "recommendedIds": recommendedIds.joined(separator: ","),
                "excludedIds": excludedIds.joined(separator: ",")
            ]
        }
    }

    var scheme: String {
        return "https"
    }

    var additionalHeaderFields: [String: String]? {
        
        switch self {
        case let .getListings(_, metadata, _, _):
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
