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
    let homepage: String
    let description: String
    let image_url: ImageUrl?
    let notificationTypes: [NotificationType]

    var appDomain: String {
        return URL(string: homepage)?.host ?? ""
    }

    var metadata: AppMetadata {
        return AppMetadata(
            name: name,
            description:
                description,
            url: appDomain,
            icons: [image_url?.sm, image_url?.md, image_url?.lg].compactMap { $0 }
        )
    }
}
