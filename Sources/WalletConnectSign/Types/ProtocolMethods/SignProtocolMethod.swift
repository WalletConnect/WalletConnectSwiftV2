import Foundation
import WalletConnectNetworking

struct PairingPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingPing"

    var request = RelayConfig(tag: 1002, prompt: false)

    var response = RelayConfig(tag: 1003, prompt: false)
}

struct PairingDeleteProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingDelete"

    var request = RelayConfig(tag: 1000, prompt: false)

    var response = RelayConfig(tag: 1001, prompt: false)
}

struct SessionProposeProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionPropose"

    var request = RelayConfig(tag: 1100, prompt: true)

    var response = RelayConfig(tag: 1101, prompt: false)
}

struct SessionSettleProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionSettle"

    var request = RelayConfig(tag: 1102, prompt: false)

    var response = RelayConfig(tag: 1103, prompt: false)
}

struct SessionUpdateProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionUpdate"

    var request = RelayConfig(tag: 1104, prompt: false)

    var response = RelayConfig(tag: 1105, prompt: false)
}

struct SessionExtendProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionExtend"

    var request = RelayConfig(tag: 1106, prompt: false)

    var response = RelayConfig(tag: 1107, prompt: false)
}

struct SessionDeleteProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionDelete"

    var request = RelayConfig(tag: 1112, prompt: false)

    var response = RelayConfig(tag: 1113, prompt: false)
}


struct SessionRequestProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionRequest"

    var request = RelayConfig(tag: 1108, prompt: true)

    var response = RelayConfig(tag: 1109, prompt: false)
}

struct SessionPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionPing"

    var request = RelayConfig(tag: 1114, prompt: false)

    var response = RelayConfig(tag: 1115, prompt: false)
}

struct SessionEventProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionEvent"

    var request = RelayConfig(tag: 1110, prompt: true)

    var response = RelayConfig(tag: 1111, prompt: false)
}
