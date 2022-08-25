import UIKit
import Combine
import Auth

final class AuthViewModel: ObservableObject {

    @Published var uri: String?

    var qrImage: UIImage? {
        return uri.map { QRCodeGenerator.generateQRCode(from: $0) }
    }

    @MainActor
    func setupInitialState() async throws {
        uri = try await Auth.instance.request(.stub())
    }

    func copyDidPressed() {
        UIPasteboard.general.string = uri
    }

    func walletDidPressed() {
        
    }
}

private extension RequestParams {
    static func stub(
        domain: String = "service.invalid",
        chainId: String = "1",
        nonce: String = "32891756",
        aud: String = "https://service.invalid/login",
        nbf: String? = nil,
        exp: String? = nil,
        statement: String? = "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
        requestId: String? = nil,
        resources: [String]? = ["ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/", "https://example.com/my-web2-claim.json"]
    ) -> RequestParams {
        return RequestParams(
            domain: domain,
            chainId: chainId,
            nonce: nonce,
            aud: aud,
            nbf: nbf,
            exp: exp,
            statement: statement,
            requestId: requestId,
            resources: resources
        )
    }
}
