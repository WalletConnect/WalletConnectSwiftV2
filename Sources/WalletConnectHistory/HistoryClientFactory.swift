import Foundation

public class HistoryClientFactory {

    public static func create(keyserver: URL, networkingInteractor: NetworkInteracting, identityClient: IdentityClient) -> HistoryClient {
        return HistoryClient(keyserver: keyserver, networkingClient: networkingInteractor, identityClient: identityClient)
    }
}
