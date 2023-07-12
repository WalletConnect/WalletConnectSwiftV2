import Foundation

struct Secrets: Decodable {
    let projectID: String
    
    enum CodingKeys: String, CodingKey {
        case projectID = "PROJECT_ID"
    }

    static func load() -> Self {
        let secretsFileUrl = Bundle.module.url(forResource: "secrets", withExtension: "json")

        do {
            guard let secretsFileUrl = secretsFileUrl, let secretsFileData = try? Data(contentsOf: secretsFileUrl) else {
                fatalError("No `secrets.json` file found. Make sure to duplicate `secrets.json.sample` and remove the `.sample` extension.")
            }

            return try JSONDecoder().decode(Self.self, from: secretsFileData)
        } catch {
            fatalError("Failed to decode secrets.json")
        }
    }
}
