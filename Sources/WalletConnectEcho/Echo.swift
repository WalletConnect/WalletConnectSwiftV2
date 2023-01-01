import Foundation

public class Echo {

    public static var instance: EchoClient = {
        guard let config = Echo.config else {
            fatalError("Error - you must call Echo.configure(_:) before accessing the shared instance.")
        }

        return EchoClientFactory.create(
            projectId: config.projectId,
            clientId: config.clientId)
    }()

    private static var config: Config?

    private init() { }

    /// Echo instance config method
    /// - Parameters:
    ///   - tenantId:
    static public func configure(projectId: String, clientId: String) {
        Echo.config = Echo.Config(clientId: clientId, projectId: projectId)
    }
}
