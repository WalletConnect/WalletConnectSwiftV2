#if DEBUG

import SwiftUI
import WalletConnectPairing

class WebSocketMock: WebSocketConnecting {
    var request: URLRequest = .init(url: URL(string: "wss://relay.walletconnect.com")!)

    var onText: ((String) -> Void)?
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var sendCallCount: Int = 0
    var isConnected: Bool = false

    func connect() {}
    func disconnect() {}
    func write(string: String, completion: (() -> Void)?) {}
}

class WebSocketFactoryMock: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        WebSocketMock()
    }
}

struct ModalSheet_Previews: PreviewProvider {
    static let projectId = "9bfe94c9cbf74aaa0597094ef561f703"
    static let metadata = AppMetadata(
        name: "Showcase App",
        description: "Showcase description",
        url: "example.wallet",
        icons: ["https://avatars.githubusercontent.com/u/37784886"]
    )

    static var previews: some View {
        ModalSheet(
            viewModel: .init(
                isShown: .constant(true),
                projectId: projectId,
                interactor: .init(
                    projectId: projectId,
                    metadata: metadata,
                    webSocketFactory: WebSocketFactoryMock()
                )
            )
        )
        .previewLayout(.sizeThatFits)
    }
}

#endif
