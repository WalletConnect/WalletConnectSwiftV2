import Foundation

struct EchoResponse: Codable {
    enum Status: String, Codable {
        case ok = "OK"
        case failed = "FAILED"
    }

    let status: Status
}
