import UIKit
import SwiftUI
import WalletConnectAuth
import WalletConnectUtils

final class SessionDetailViewController: UIHostingController<SessionDetailView> {
    
    private let viewModel: SessionDetailViewModel
        
    init(session: Session, client: AuthClient) {
        self.viewModel = SessionDetailViewModel(session: session, client: client)
        super.init(rootView: SessionDetailView(viewModel: viewModel))
        
        rootView.didPressSessionRequest = { [weak self] request in
            self?.showSessionRequest(request)
        }
    }
                   
    private func showSessionRequest(_ request: Request) {
        let viewController = RequestViewController(request)
        viewController.onSign = { [unowned self] in
            let result = Signer.signEth(request: request)
            let response = JSONRPCResponse<AnyCodable>(id: request.id, result: result)
            Auth.instance.respond(topic: request.topic, response: .response(response))
            viewModel.objectWillChange.send()
        }
        viewController.onReject = { [unowned self] in
            Auth.instance.respond(
                topic: request.topic,
                response: .error(JSONRPCErrorResponse(
                    id: request.id,
                    error: JSONRPCErrorResponse.Error(code: 0, message: ""))
                )
            )
            viewModel.objectWillChange.send()
        }
        present(viewController, animated: true)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
