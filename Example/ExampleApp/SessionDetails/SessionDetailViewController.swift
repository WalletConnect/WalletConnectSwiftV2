import UIKit
import SwiftUI
import WalletConnectSign
import WalletConnectUtils

final class SessionDetailViewController: UIHostingController<SessionDetailView> {

    private let viewModel: SessionDetailViewModel

    init(session: Session, client: SignClient) {
        self.viewModel = SessionDetailViewModel(session: session, client: client)
        super.init(rootView: SessionDetailView(viewModel: viewModel))

        rootView.didPressSessionRequest = { [weak self] request in
            self?.showSessionRequest(request)
        }
    }

    func reload() {
        viewModel.objectWillChange.send()
    }

    private func showSessionRequest(_ request: Request) {
        let viewController = RequestViewController(request)
        viewController.onSign = { [unowned self] in
            let result = Signer.signEth(request: request)
            let response = JSONRPCResponse<AnyCodable>(id: request.id, result: result)
            respondOnSign(request: request, response: response)
            reload()
        }
        viewController.onReject = { [unowned self] in
            respondOnReject(request: request)
            reload()
        }
        present(viewController, animated: true)
    }

    private func respondOnSign(request: Request, response: JSONRPCResponse<AnyCodable>) {
        print("[WALLET] Respond on Sign")
        Task {
            do {
                try await Sign.instance.respond(topic: request.topic, response: .response(response))
            } catch {
                print("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }

    private func respondOnReject(request: Request) {
        print("[WALLET] Respond on Reject")
        Task {
            do {
                try await Sign.instance.respond(
                    topic: request.topic,
                    response: .error(JSONRPCErrorResponse(
                        id: request.id,
                        error: JSONRPCErrorResponse.Error(code: 0, message: ""))
                    )
                )
            } catch {
                print("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
