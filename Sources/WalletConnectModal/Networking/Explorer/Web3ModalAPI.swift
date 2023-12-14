import Foundation

enum Web3ModalAPI: HTTPService {
    struct GetWalletsParams {
        let page: Int
        let entries: Int
        let search: String?
        let projectId: String
        let metadata: AppMetadata
        let recommendedIds: [String]
        let excludedIds: [String]
    }
    
    struct GetIosDataParams {
        let projectId: String
        let metadata: AppMetadata
    }
    
    case getWallets(params: GetWalletsParams)
    case getIosData(params: GetIosDataParams)

    var path: String {
        switch self {
        case .getWallets: return "/getWallets"
        case .getIosData: return "/getIosData"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getWallets: return .get
        case .getIosData: return .get
        }
    }

    var body: Data? {
        nil
    }

    var queryParameters: [String: String]? {
        switch self {
        case let .getWallets(params):
            return [
                "page": "\(params.page)",
                "entries": "\(params.entries)",
                "search": params.search ?? "",
                "recommendedIds": params.recommendedIds.joined(separator: ","),
                "excludedIds": params.excludedIds.joined(separator: ","),
                "platform": "ios",
            ]
            .compactMapValues { value in
                value.isEmpty ? nil : value
            }
        case let .getIosData(params):
            return [
                "projectId": params.projectId,
                "metadata": params.metadata.name
            ]
        }
    }

    var scheme: String {
        return "https"
    }

    var additionalHeaderFields: [String: String]? {
        switch self {
        case let .getWallets(params):
            return [
                "x-project-id": params.projectId,
                "x-sdk-version": WalletConnectModal.Config.sdkVersion,
                "x-sdk-type": WalletConnectModal.Config.sdkType,
                "Referer": params.metadata.name
            ]
        case let .getIosData(params):
            return [
                "x-project-id": params.projectId,
                "x-sdk-version": WalletConnectModal.Config.sdkVersion,
                "x-sdk-type": WalletConnectModal.Config.sdkType,
                "Referer": params.metadata.name
            ]
        }
    }
}
