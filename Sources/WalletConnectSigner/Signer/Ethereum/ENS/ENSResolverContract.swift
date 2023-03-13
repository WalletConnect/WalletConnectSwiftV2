import Foundation

actor ENSResolverContract {

    private let address: String
    private let projectId: String
    private let chainId: String
    private let httpClient: HTTPClient

    init(address: String, projectId: String, chainId: String, httpClient: HTTPClient) {
        self.address = address
        self.projectId = projectId
        self.chainId = chainId
        self.httpClient = httpClient
    }

    func name(namehash: Data) async throws -> String {
        let encoder = ENSNameMethod(namehash: namehash)
        let call = EthCall(to: address, data: encoder.encode())
        let params = AnyCodable([AnyCodable(call), AnyCodable("latest")])
        let request = RPCRequest(method: "eth_call", params: params)
        let data = try JSONEncoder().encode(request)
        let httpService = RPCService(data: data, projectId: projectId, chainId: chainId)
        let response = try await httpClient.request(RPCResponse.self, at: httpService)
        return try validateResponse(response)
    }
}

private extension ENSResolverContract {

    enum Errors: Error {
        case invalidResponse
    }

    func validateResponse(_ response: RPCResponse) throws -> String {
        guard let result = try response.result?.get(String.self)
        else { throw Errors.invalidResponse }

        let (at, _) = try ContractDecoder.int(result)
        return try ContractDecoder.string(result, at: at)
    }
}
