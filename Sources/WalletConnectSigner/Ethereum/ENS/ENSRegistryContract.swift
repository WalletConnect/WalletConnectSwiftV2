import Foundation

actor ENSRegistryContract {

    private let address: String
    private let projectId: String
    private let httpClient: HTTPClient

    init(address: String, projectId: String, httpClient: HTTPClient) {
        self.address = address
        self.projectId = projectId
        self.httpClient = httpClient
    }

    func resolver(namehash: Data, chainId: String) async throws -> String {
        let encoder = ENSResolverMethod(namehash: namehash)
        let call = EthCall(to: address, data: encoder.encode())
        let params = AnyCodable([AnyCodable(call), AnyCodable("latest")])
        let request = RPCRequest(method: "eth_call", params: params)
        let data = try JSONEncoder().encode(request)
        let httpService = RPCService(data: data, projectId: projectId, chainId: chainId)
        let response = try await httpClient.request(RPCResponse.self, at: httpService)
        return try validateResponse(response)
    }
}

private extension ENSRegistryContract {

    enum Errors: Error {
        case invalidResponse
    }

    func validateResponse(_ response: RPCResponse) throws -> String {
        guard let result = try response.result?.get(String.self)
        else { throw Errors.invalidResponse }

        return try ContractDecoder.address(result).0
    }
}
