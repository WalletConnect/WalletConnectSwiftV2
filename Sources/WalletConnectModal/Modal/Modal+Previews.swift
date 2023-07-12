#if DEBUG

import SwiftUI

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

struct ModalContainerView_Previews: PreviewProvider {
    
    static var previews: some View {
        Content()
            .previewLayout(.sizeThatFits)
    }
    
    struct Content: View {
        
        init() {
            
            let projectId = Secrets.load().projectID
            let metadata = AppMetadata(
                name: "Showcase App",
                description: "Showcase description",
                url: "example.wallet",
                icons: ["https://avatars.githubusercontent.com/u/37784886"]
            )
            
            Networking.configure(projectId: projectId, socketFactory: WebSocketFactoryMock())
            WalletConnectModal.configure(projectId: projectId, metadata: metadata)
        }
        
        var body: some View {
            ModalContainerView()
        }
    }
}

#endif
