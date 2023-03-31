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
        let response = try await ethCall(with: encoder.encode())
        return try validateNameResponse(response)
    }

    func address(namehash: Data) async throws -> String {
        let encoder = ENSAddressMethod(namehash: namehash)
        let response = try await ethCall(with: encoder.encode())
        return try validateAddressResponse(response)
    }
}

private extension ENSResolverContract {

    enum Errors: Error {
        case invalidResponse
        case recordNotFound
    }

    func ethCall(with data: String) async throws -> RPCResponse {
        let call = EthCall(to: address, data: data)
        let params = AnyCodable([AnyCodable(call), AnyCodable("latest")])
        let request = RPCRequest(method: "eth_call", params: params)
        let data = try JSONEncoder().encode(request)
        let httpService = RPCService(data: data, projectId: projectId, chainId: chainId)
        return try await httpClient.request(RPCResponse.self, at: httpService)
    }

    func validateNameResponse(_ response: RPCResponse) throws -> String {
        guard let result = try response.result?.get(String.self)
        else { throw Errors.invalidResponse }

        let (at, _) = try ContractDecoder.int(result)
        return try ContractDecoder.string(result, at: at)
    }

    func validateAddressResponse(_ response: RPCResponse) throws -> String {
        guard let result = try response.result?.get(String.self)
        else { throw Errors.invalidResponse }

        let address = try ContractDecoder.address(result).0

        guard address != "0x0000000000000000000000000000000000000000" else {
            throw Errors.recordNotFound
        }

        return address
    }
}
