import Foundation
import WalletConnectAuth

struct SessionNamespaceViewModel {
    let namespace: SessionNamespace
    
    var accounts: [Account] {
        namespace.accounts.sorted(by: {
            $0.absoluteString < $1.absoluteString
        })
    }
    var methods: [String] {
        namespace.methods.sorted()
    }

    var events: [String] {
        namespace.events.sorted()
    }
}
