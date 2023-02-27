import Foundation

public final class IdentityClientFactory {

    public static func create(
        keyserver: URL,
        keychain: KeychainStorageProtocol,
        logger: ConsoleLogging
    ) -> IdentityClient {
        let kms = KeyManagementService(keychain: keychain)
        let httpService = HTTPNetworkClient(host: keyserver.host!)
        let identityStorage = IdentityStorage(keychain: keychain)
        let identityNetworkService = IdentityNetworkService(httpService: httpService)
        let identityService = IdentityService(keyserverURL: keyserver, kms: kms, storage: identityStorage, networkService: identityNetworkService, iatProvader: DefaultIATProvider(), messageFormatter: SIWECacaoFormatter())
        return IdentityClient(
            identityService: identityService,
            identityStorage: identityStorage,
            logger: logger
        )
    }
}
