import Foundation

struct NotifyConfig: Codable {
    struct NotificationType: Codable {
        let id: String
        let name: String
        let description: String
    }
    struct ImageUrl: Codable {
        let sm: String?
        let md: String?
        let lg: String?
    }
    let id: String
    let name: String
    let homepage: String?
    let description: String
    let dapp_url: String
    let image_url: ImageUrl?
    let notificationTypes: [NotificationType]

    var appDomain: String {
        return URL(string: dapp_url)?.host ?? dapp_url
    }

    var metadata: AppMetadata {
        return AppMetadata(
            name: name,
            description: description,
            url: appDomain,
            icons: [image_url?.sm, image_url?.md, image_url?.lg].compactMap { $0 }, 
            redirect: AppMetadata.Redirect(native: "", universal: nil)
        )
    }
}
